import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'migration_registry.dart';
import 'schema_lock.dart';
import 'sql_object_parser.dart';
import 'sql_source_discovery.dart';

class AdoptSchemaException implements Exception {
  const AdoptSchemaException(this.message);

  final String message;

  @override
  String toString() => 'AdoptSchemaException: $message';
}

class AdoptSchemaOptions {
  const AdoptSchemaOptions({
    required this.repoRoot,
    this.qualifiedName,
    this.module,
  }) : assert(
          (qualifiedName != null) ^ (module != null),
          'specify exactly one of qualifiedName or module',
        );

  final Directory repoRoot;

  /// Fully-qualified object name, e.g. `catalog.search_products`.
  final String? qualifiedName;

  /// Adopt every REGISTRY entry under this schema / module name.
  final String? module;
}

class AdoptSchemaResult {
  const AdoptSchemaResult({required this.adopted});

  /// Qualified names adopted, sorted.
  final List<String> adopted;
}

class _PreparedAdopt {
  const _PreparedAdopt({
    required this.qualifiedName,
    required this.schema,
    required this.name,
    required this.relativePath,
    required this.content,
    required this.hash,
    required this.signatures,
    required this.migrationName,
  });

  final String qualifiedName;
  final String schema;
  final String name;
  final String relativePath;
  final String content;
  final String hash;
  final List<String> signatures;
  final String migrationName;
}

/// Moves RPC ownership from [REGISTRY.yaml] into declarative sources + lock.
///
/// Does not generate a migration: [SchemaLockEntry.lastMigration] stays the
/// REGISTRY source migration so a subsequent `migrate:generate` is a no-op.
class AdoptSchemaService {
  AdoptSchemaResult adopt(AdoptSchemaOptions options) {
    final registryFile = File('${options.repoRoot.path}/$registryRelativePath');
    final registry = MigrationRegistry.load(registryFile);
    final targets = _targets(options, registry);
    if (targets.isEmpty) {
      throw AdoptSchemaException(
        options.module != null
            ? 'no REGISTRY entries found for module "${options.module}"'
            : 'nothing to adopt',
      );
    }

    final lock = SchemaLock.load(
      File('${options.repoRoot.path}/$schemaLockRelativePath'),
    );
    final prepared = [
      for (final target in targets)
        _prepareOne(
          repoRoot: options.repoRoot,
          registry: registry,
          lock: lock,
          schema: target.$1,
          name: target.$2,
        ),
    ];

    for (final item in prepared) {
      final target = File('${options.repoRoot.path}/${item.relativePath}');
      target.parent.createSync(recursive: true);
      target.writeAsStringSync(item.content);
      lock.entries[item.qualifiedName] = SchemaLockEntry(
        sourcePath: item.relativePath,
        hash: item.hash,
        signatures: item.signatures,
        lastMigration: item.migrationName,
      );
      registry.removeOwner(schema: item.schema, functionName: item.name);
    }

    registry.write(registryFile);
    lock.write(File('${options.repoRoot.path}/$schemaLockRelativePath'));
    return AdoptSchemaResult(
      adopted: [for (final item in prepared) item.qualifiedName]..sort(),
    );
  }

  List<(String, String)> _targets(
    AdoptSchemaOptions options,
    MigrationRegistry registry,
  ) {
    if (options.qualifiedName case final qualified?) {
      final parts = qualified.split('.');
      if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
        throw AdoptSchemaException(
          'qualified name must be schema.name, got "$qualified"',
        );
      }
      return [(parts[0], parts[1])];
    }
    final module = options.module!;
    final functions = registry.schemas[module];
    if (functions == null || functions.isEmpty) {
      return const [];
    }
    return [
      for (final name in (functions.keys.toList()..sort())) (module, name),
    ];
  }

  _PreparedAdopt _prepareOne({
    required Directory repoRoot,
    required MigrationRegistry registry,
    required SchemaLock lock,
    required String schema,
    required String name,
  }) {
    final qualified = '$schema.$name';
    if (lock.entries.containsKey(qualified)) {
      throw AdoptSchemaException('$qualified is already in schema.lock.yaml');
    }

    final migrationName = registry.ownerMigration(
      schema: schema,
      functionName: name,
    );
    if (migrationName == null) {
      throw AdoptSchemaException(
        '$qualified is not in REGISTRY.yaml',
      );
    }

    final migrationFile =
        File('${repoRoot.path}/supabase/migrations/$migrationName');
    if (!migrationFile.existsSync()) {
      throw AdoptSchemaException(
        'migration "$migrationName" for $qualified not found at '
        '${migrationFile.path}',
      );
    }

    final objects = parseSqlObjects(migrationFile.readAsStringSync())
        .where(
          (object) =>
              object.kind == SqlObjectKind.function &&
              object.schema == schema &&
              object.name == name,
        )
        .toList();
    if (objects.isEmpty) {
      throw AdoptSchemaException(
        '$qualified not found in migration $migrationName',
      );
    }

    final relativePath = _sourceRelativePath(
      repoRoot: repoRoot,
      schema: schema,
      name: name,
    );
    final target = File('${repoRoot.path}/$relativePath');
    if (target.existsSync()) {
      throw AdoptSchemaException(
        'refusing to overwrite existing source $relativePath',
      );
    }

    final content =
        '${objects.map((object) => object.sql.trimRight()).join('\n\n')}\n'
            .replaceAll('\r\n', '\n');
    return _PreparedAdopt(
      qualifiedName: qualified,
      schema: schema,
      name: name,
      relativePath: relativePath,
      content: content,
      hash: 'sha256:${sha256.convert(utf8.encode(content))}',
      signatures: objects.map((object) => object.signature!).toList(),
      migrationName: migrationName,
    );
  }

  /// Module root when `modules/<schema>` exists; otherwise shared SQL root.
  String _sourceRelativePath({
    required Directory repoRoot,
    required String schema,
    required String name,
  }) {
    final moduleRoot = Directory('${repoRoot.path}/modules/$schema');
    if (moduleRoot.existsSync()) {
      return 'modules/$schema/$moduleSqlRelativePath/'
          '${objectKindDirs[SqlObjectKind.function]}/$name.sql';
    }
    return '$sharedSqlRelativePath/$schema/'
        '${objectKindDirs[SqlObjectKind.function]}/$name.sql';
  }
}
