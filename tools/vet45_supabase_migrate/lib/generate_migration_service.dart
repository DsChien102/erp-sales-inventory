import 'dart:io';

import 'migration_header.dart';
import 'promote_drafts_service.dart';
import 'schema_lock.dart';
import 'sql_object_parser.dart';
import 'sql_object_render.dart';
import 'sql_source_discovery.dart';

export 'sql_source_discovery.dart' show SchemaSourceException, objectKindDirs;

/// Generated migration body regions, in dependency-friendly fixed order.
const generatedRegionOrder = <SqlObjectKind>[
  SqlObjectKind.function,
  SqlObjectKind.view,
  SqlObjectKind.trigger,
  SqlObjectKind.policy,
];

final _intentPattern = RegExp(r'^[a-z0-9]+(?:_[a-z0-9]+)*$');

final _kindDirByName = <String, SqlObjectKind>{
  for (final MapEntry(key: kind, value: dir) in objectKindDirs.entries) dir: kind,
};

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

/// One object to create and/or drop in a generated migration.
class _PendingObject {
  const _PendingObject({
    required this.qualifiedName,
    required this.kind,
    required this.dropTargets,
    this.source,
  });

  final String qualifiedName;
  final SqlObjectKind kind;

  /// Function overload signatures, or trigger/policy `"name on schema.table"`.
  final List<String> dropTargets;

  /// Null when the source file was deleted.
  final SqlSource? source;
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
    final pending = _diffSources(sources, lock);
    if (pending.isEmpty) {
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
    final draftsDirectory = _promoteDrafts.draftsDir(options.repoRoot);
    final preDraft = _intentDraftFile(draftsDirectory, options.intent, 'pre');
    final postDraft = _intentDraftFile(draftsDirectory, options.intent, 'post');
    final migration = _buildMigration(
      fileName: '${timestamp}_${options.intent}.sql',
      intent: options.intent,
      pending: pending,
      preSql: _readDraftBody(preDraft),
      postSql: _readDraftBody(postDraft),
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

    for (final change in pending) {
      final source = change.source;
      if (source == null) {
        lock.entries.remove(change.qualifiedName);
      } else {
        lock.entries[change.qualifiedName] = SchemaLockEntry(
          sourcePath: source.relativePath,
          hash: source.hash,
          signatures: source.signatures,
          lastMigration: migration.fileName,
        );
      }
    }
    lock.write(lockFile(options.repoRoot));
    _archiveIntentDraft(
      draftsDirectory: draftsDirectory,
      timestamp: timestamp,
      intent: options.intent,
      role: 'pre',
      draft: preDraft,
    );
    _archiveIntentDraft(
      draftsDirectory: draftsDirectory,
      timestamp: timestamp,
      intent: options.intent,
      role: 'post',
      draft: postDraft,
    );

    return GenerateMigrationResult(migration: migration, written: target);
  }

  File _intentDraftFile(Directory draftsDirectory, String intent, String role) {
    return File('${draftsDirectory.path}/$intent.$role.sql');
  }

  /// Null when the draft file is missing; otherwise the file body (trimmed right).
  String? _readDraftBody(File draft) {
    if (!draft.existsSync()) {
      return null;
    }
    // Keep leading `--` comments: pre/post drafts are hand-written DDL, not
    // Kind/Intent header blocks.
    return draft.readAsStringSync().trimRight();
  }

  void _archiveIntentDraft({
    required Directory draftsDirectory,
    required String timestamp,
    required String intent,
    required String role,
    required File draft,
  }) {
    if (!draft.existsSync()) {
      return;
    }
    final archiveDir = Directory('${draftsDirectory.path}/_archive')
      ..createSync(recursive: true);
    final target = File('${archiveDir.path}/${timestamp}_$intent.$role.sql');
    if (target.existsSync()) {
      throw StateError(
        'Refusing to overwrite archived draft: ${target.path}',
      );
    }
    draft.renameSync(target.path);
  }

  List<_PendingObject> _diffSources(List<SqlSource> sources, SchemaLock lock) {
    final problems = <String>[];
    final byName = {
      for (final source in sources) source.qualifiedName: source,
    };
    final pending = <_PendingObject>[];

    for (final MapEntry(key: name, value: entry) in lock.entries.entries) {
      if (byName.containsKey(name)) {
        continue;
      }
      final kind = _kindFromSourcePath(entry.sourcePath);
      if (kind == null) {
        problems.add(
          '$name is locked at ${entry.sourcePath} but the object kind is '
          'unknown; write any required drop in '
          'supabase/migrations/_drafts/<intent>.pre.sql (region pre), '
          'then fix or remove this lock entry',
        );
        continue;
      }
      if (entry.signatures.isEmpty &&
          (kind == SqlObjectKind.function ||
              kind == SqlObjectKind.trigger ||
              kind == SqlObjectKind.policy)) {
        problems.add(
          '$name: cannot auto-drop ${kind.name} without '
          '${kind == SqlObjectKind.function ? 'signatures' : 'ON table'} '
          'in the lock; write the drop in '
          'supabase/migrations/_drafts/<intent>.pre.sql (region pre), '
          'then remove this lock entry after generate',
        );
        continue;
      }
      pending.add(
        _PendingObject(
          qualifiedName: name,
          kind: kind,
          dropTargets: entry.signatures,
          source: null,
        ),
      );
    }

    for (final source in sources) {
      final entry = lock.entries[source.qualifiedName];
      if (entry == null) {
        pending.add(
          _PendingObject(
            qualifiedName: source.qualifiedName,
            kind: source.kind,
            dropTargets: const [],
            source: source,
          ),
        );
        continue;
      }
      final current = source.signatures.map(_overloadIdentity).toSet();
      final removed = entry.signatures
          .where((signature) => !current.contains(_overloadIdentity(signature)))
          .toList();
      if (entry.hash != source.hash ||
          entry.sourcePath != source.relativePath ||
          removed.isNotEmpty) {
        pending.add(
          _PendingObject(
            qualifiedName: source.qualifiedName,
            kind: source.kind,
            dropTargets: removed,
            source: source,
          ),
        );
      }
    }

    if (problems.isNotEmpty) {
      throw SchemaSourceException(problems);
    }
    return pending
      ..sort((a, b) => a.qualifiedName.compareTo(b.qualifiedName));
  }

  SqlObjectKind? _kindFromSourcePath(String relativePath) {
    for (final segment in relativePath.split('/')) {
      final kind = _kindDirByName[segment];
      if (kind != null) {
        return kind;
      }
    }
    return null;
  }

  /// Signature without parameter defaults, lowercased: `create or replace`
  /// may change defaults but not the parameter list itself.
  ///
  /// Trigger/policy lock targets (`name on schema.table`) have no `(...)`.
  String _overloadIdentity(String signature) {
    final open = signature.indexOf('(');
    if (open == -1) {
      return signature.toLowerCase();
    }
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
    required List<_PendingObject> pending,
    String? preSql,
    String? postSql,
  }) {
    final touches = pending.map((change) => change.qualifiedName).toList()
      ..sort();
    final header = MigrationHeader(
      kind: 'generated',
      intent: intent,
      touches: touches,
    );
    final buffer = StringBuffer()
      ..writeln(header.toCommentBlock().trimRight())
      ..writeln(
        '-- Generated by tools/vet45_supabase_migrate/bin/generate_migration.dart',
      );

    if (preSql != null) {
      _writeRegion(buffer, 'pre', preSql);
    }

    for (final kind in generatedRegionOrder) {
      final regionObjects = pending.where((change) => change.kind == kind).toList()
        ..sort((a, b) => a.qualifiedName.compareTo(b.qualifiedName));
      if (regionObjects.isEmpty) {
        continue;
      }
      _writeRegion(
        buffer,
        objectKindDirs[kind]!,
        regionObjects.map(_renderPending).join('\n\n'),
      );
    }

    if (postSql != null) {
      _writeRegion(buffer, 'post', postSql);
    }

    return GeneratedMigration(
      fileName: fileName,
      touches: touches,
      sql: buffer.toString(),
    );
  }

  void _writeRegion(StringBuffer buffer, String name, String body) {
    buffer
      ..writeln()
      ..writeln('-- region: $name')
      ..writeln();
    if (body.isNotEmpty) {
      buffer.writeln(body);
    }
  }

  String _renderPending(_PendingObject change) {
    final parts = <String>[
      ..._renderDrops(change),
      if (change.source case final source?) renderDeclarativeSource(source),
    ];
    return parts.join('\n');
  }

  List<String> _renderDrops(_PendingObject change) {
    return switch (change.kind) {
      SqlObjectKind.function => [
          for (final signature in change.dropTargets)
            'drop function if exists $signature;',
        ],
      SqlObjectKind.view => [
          if (change.source == null)
            'drop view if exists ${change.qualifiedName};',
        ],
      SqlObjectKind.trigger => [
          for (final target in change.dropTargets)
            dropRelationFromLockTarget(SqlObjectKind.trigger, target),
        ],
      SqlObjectKind.policy => [
          for (final target in change.dropTargets)
            dropRelationFromLockTarget(SqlObjectKind.policy, target),
        ],
    };
  }
}
