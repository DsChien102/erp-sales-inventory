import 'dart:io';

import 'migration_header.dart';
import 'promote_drafts_service.dart';
import 'schema_lock.dart';
import 'sql_source_discovery.dart';

export 'sql_source_discovery.dart' show SchemaSourceException;

final _intentPattern = RegExp(r'^[a-z0-9]+(?:_[a-z0-9]+)*$');

class GenerateMigrationOptions {
  const GenerateMigrationOptions({
    required this.repoRoot,
    required this.intent,
    this.startTimestamp,
    this.referenceTime,
    this.dryRun = false,
  });

  final Directory repoRoot;

  /// snake_case slug used for the file name and `-- Intent:` header.
  final String intent;
  final String? startTimestamp;

  /// Defaults to [DateTime.now] when allocating the migration id.
  final DateTime? referenceTime;
  final bool dryRun;
}

class GeneratedMigration {
  const GeneratedMigration({
    required this.fileName,
    required this.touches,
    required this.sql,
  });

  final String fileName;

  /// `schema.name` of every object in the migration.
  final List<String> touches;
  final String sql;
}

class GenerateMigrationResult {
  const GenerateMigrationResult({this.migration, this.written});

  /// Null when no source differs from the lock.
  final GeneratedMigration? migration;

  /// Null on dry run or when nothing was generated.
  final File? written;
}

/// Generates a `Kind: generated` migration from declarative sources that
/// differ from `supabase/schema.lock.yaml`, then updates the lock.
class GenerateMigrationService {
  GenerateMigrationService({
    SqlSourceDiscovery? discovery,
    PromoteDraftsService? promoteDrafts,
  })  : _discovery = discovery ?? SqlSourceDiscovery(),
        _promoteDrafts = promoteDrafts ?? PromoteDraftsService();

  final SqlSourceDiscovery _discovery;
  final PromoteDraftsService _promoteDrafts;

  File lockFile(Directory repoRoot) =>
      File('${repoRoot.path}/$schemaLockRelativePath');

  GenerateMigrationResult generate(GenerateMigrationOptions options) {
    if (!_intentPattern.hasMatch(options.intent)) {
      throw ArgumentError.value(
        options.intent,
        'intent',
        'must be a snake_case slug (a-z, 0-9, _)',
      );
    }

    final sources = _discovery.discover(options.repoRoot);
    final lock = SchemaLock.load(lockFile(options.repoRoot));
    final changed = _changedSources(sources, lock);
    if (changed.isEmpty) {
      return const GenerateMigrationResult();
    }

    final migrationsDirectory = _promoteDrafts.migrationsDir(options.repoRoot);
    final timestamp = _promoteDrafts
        .allocateTimestamps(
          count: 1,
          migrationsDirectory: migrationsDirectory,
          startTimestamp: options.startTimestamp,
          referenceTime: options.referenceTime,
        )
        .single;
    final migration = _buildMigration(
      fileName: '${timestamp}_${options.intent}.sql',
      intent: options.intent,
      changed: changed,
    );
    if (options.dryRun) {
      return GenerateMigrationResult(migration: migration);
    }

    final target = File('${migrationsDirectory.path}/${migration.fileName}');
    if (target.existsSync()) {
      throw StateError('Refusing to overwrite existing migration: ${target.path}');
    }
    migrationsDirectory.createSync(recursive: true);
    target.writeAsStringSync(migration.sql);

    for (final source in changed) {
      lock.entries[source.qualifiedName] = SchemaLockEntry(
        sourcePath: source.relativePath,
        hash: source.hash,
        signatures: source.signatures,
        lastMigration: migration.fileName,
      );
    }
    lock.write(lockFile(options.repoRoot));

    return GenerateMigrationResult(migration: migration, written: target);
  }

  List<SqlSource> _changedSources(List<SqlSource> sources, SchemaLock lock) {
    final problems = <String>[];
    final sourceNames = sources.map((source) => source.qualifiedName).toSet();
    for (final MapEntry(key: name, value: entry) in lock.entries.entries) {
      if (!sourceNames.contains(name)) {
        problems.add(
          '$name is locked but ${entry.sourcePath} is missing; '
          'dropping objects is not supported yet — restore the source',
        );
      }
    }

    final changed = <SqlSource>[];
    for (final source in sources) {
      final entry = lock.entries[source.qualifiedName];
      if (entry == null) {
        changed.add(source);
        continue;
      }
      final current = source.signatures.map(_overloadIdentity).toSet();
      final removed = entry.signatures
          .where((signature) => !current.contains(_overloadIdentity(signature)))
          .toList();
      if (removed.isNotEmpty) {
        problems.add(
          '${source.relativePath}: removed or changed overload '
          '${removed.join(', ')}; dropping overloads is not supported yet',
        );
      }
      if (entry.hash != source.hash || entry.sourcePath != source.relativePath) {
        changed.add(source);
      }
    }

    if (problems.isNotEmpty) {
      throw SchemaSourceException(problems);
    }
    return changed;
  }

  /// Signature without parameter defaults, lowercased: `create or replace`
  /// may change defaults but not the parameter list itself.
  String _overloadIdentity(String signature) {
    final open = signature.indexOf('(');
    final args = _splitTopLevelCommas(
      signature.substring(open + 1, signature.length - 1),
    ).map(
      (arg) => arg
          .replaceFirst(
            RegExp(r'(\s+default\b|\s*=).*$', caseSensitive: false, dotAll: true),
            '',
          )
          .trim(),
    );
    return '${signature.substring(0, open)}(${args.join(', ')})'.toLowerCase();
  }

  List<String> _splitTopLevelCommas(String args) {
    final parts = <String>[];
    var depth = 0;
    var start = 0;
    String? quote;
    for (var i = 0; i < args.length; i++) {
      final c = args[i];
      if (quote != null) {
        if (c == quote) {
          quote = null;
        }
      } else if (c == "'" || c == '"') {
        quote = c;
      } else if (c == '(' || c == '[') {
        depth++;
      } else if (c == ')' || c == ']') {
        depth--;
      } else if (c == ',' && depth == 0) {
        parts.add(args.substring(start, i));
        start = i + 1;
      }
    }
    final last = args.substring(start);
    if (last.trim().isNotEmpty) {
      parts.add(last);
    }
    return parts;
  }

  GeneratedMigration _buildMigration({
    required String fileName,
    required String intent,
    required List<SqlSource> changed,
  }) {
    final touches = changed.map((source) => source.qualifiedName).toList();
    final header = MigrationHeader(
      kind: 'generated',
      intent: intent,
      touches: touches,
    );
    final functions =
        changed.map((source) => source.content.trimRight()).join('\n\n');
    final sql = '''
${header.toCommentBlock()}
-- Generated by tools/vet45_supabase_migrate/bin/generate_migration.dart

-- region: functions

$functions
''';
    return GeneratedMigration(fileName: fileName, touches: touches, sql: sql);
  }
}
