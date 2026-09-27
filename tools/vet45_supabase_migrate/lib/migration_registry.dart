import 'dart:io';

const registryRelativePath = 'supabase/migrations/REGISTRY.yaml';

class MigrationRegistry {
  MigrationRegistry({
    required this.schemas,
    required this.bootstrapGrandfathered,
    this.phase2Notes = const [],
  });

  final Map<String, Map<String, String>> schemas;
  final List<String> bootstrapGrandfathered;
  final List<String> phase2Notes;

  static MigrationRegistry empty() {
    return MigrationRegistry(
      schemas: {
        'catalog': {},
        'iam': {},
        'platform': {},
      },
      bootstrapGrandfathered: const [],
    );
  }

  static MigrationRegistry load(File file) {
    if (!file.existsSync()) {
      return MigrationRegistry.empty();
    }
    return MigrationRegistry.parse(file.readAsStringSync());
  }

  static MigrationRegistry parse(String content) {
    final schemas = <String, Map<String, String>>{};
    final bootstrapGrandfathered = <String>[];
    final phase2Notes = <String>[];

    String? currentSchema;
    String? currentSection;

    for (final rawLine in content.split('\n')) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        if (trimmed.startsWith('# Phase 2')) {
          phase2Notes.add(trimmed.substring(1).trim());
        }
        continue;
      }

      if (trimmed.endsWith(':') && !trimmed.contains(' ')) {
        final section = trimmed.substring(0, trimmed.length - 1);
        if (section == 'bootstrap_grandfathered') {
          currentSection = section;
          currentSchema = null;
        } else {
          currentSection = 'schema';
          currentSchema = section;
          schemas.putIfAbsent(currentSchema, () => {});
        }
        continue;
      }

      if (currentSection == 'bootstrap_grandfathered') {
        if (trimmed.startsWith('- ')) {
          bootstrapGrandfathered.add(trimmed.substring(2).trim());
        }
        continue;
      }

      if (currentSchema != null && trimmed.contains(':')) {
        final colon = trimmed.indexOf(':');
        final key = trimmed.substring(0, colon).trim();
        var value = trimmed.substring(colon + 1).trim();
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }
        schemas.putIfAbsent(currentSchema, () => {});
        schemas[currentSchema]![key] = value;
      }
    }

    return MigrationRegistry(
      schemas: schemas,
      bootstrapGrandfathered: bootstrapGrandfathered,
      phase2Notes: phase2Notes,
    );
  }

  String serialize() {
    final buffer = StringBuffer()
      ..writeln('# RPC ownership registry — last migration defining each function.')
      ..writeln('# Update when promoting Kind: patch|surgical migrations.')
      ..writeln('# Regenerate owners: melos run migrate:seed-registry -- --write')
      ..writeln();

    for (final schema in _sortedSchemaKeys) {
      final functions = schemas[schema];
      if (functions == null || functions.isEmpty) {
        continue;
      }
      buffer.writeln('$schema:');
      final keys = functions.keys.toList()..sort();
      for (final name in keys) {
        buffer.writeln('  $name: ${functions[name]}');
      }
      buffer.writeln();
    }

    buffer.writeln('bootstrap_grandfathered:');
    for (final file in bootstrapGrandfathered) {
      buffer.writeln('  - $file');
    }
    buffer.writeln();

    if (phase2Notes.isNotEmpty) {
      for (final note in phase2Notes) {
        buffer.writeln('# $note');
      }
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  List<String> get _sortedSchemaKeys {
    final keys = schemas.keys.toList()
      ..sort((a, b) {
        const order = ['catalog', 'iam', 'platform'];
        final ai = order.indexOf(a);
        final bi = order.indexOf(b);
        if (ai != -1 && bi != -1) {
          return ai.compareTo(bi);
        }
        return a.compareTo(b);
      });
    return keys;
  }

  void setOwner({
    required String schema,
    required String functionName,
    required String migrationFile,
  }) {
    schemas.putIfAbsent(schema, () => {});
    schemas[schema]![functionName] = migrationFile;
  }

  void removeOwner({
    required String schema,
    required String functionName,
  }) {
    final functions = schemas[schema];
    if (functions == null) {
      return;
    }
    functions.remove(functionName);
    if (functions.isEmpty) {
      schemas.remove(schema);
    }
  }

  String? ownerMigration({
    required String schema,
    required String functionName,
  }) {
    return schemas[schema]?[functionName];
  }

  bool isGrandfathered(String migrationFileName) {
    return bootstrapGrandfathered.contains(migrationFileName);
  }

  void write(File file) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('${serialize()}\n');
  }
}
