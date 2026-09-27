import 'dart:convert';
import 'dart:io';

const schemaLockRelativePath = 'supabase/schema.lock.yaml';

class SchemaLockEntry {
  const SchemaLockEntry({
    required this.sourcePath,
    required this.hash,
    required this.signatures,
    required this.lastMigration,
  });

  /// Repo-relative path with `/` separators.
  final String sourcePath;

  /// `sha256:<hex>` of the source file content.
  final String hash;
  final List<String> signatures;
  final String lastMigration;
}

/// Repo-wide lock of declarative SQL objects, keyed by `schema.name`.
class SchemaLock {
  SchemaLock(this.entries);

  final Map<String, SchemaLockEntry> entries;

  static SchemaLock load(File file) {
    if (!file.existsSync()) {
      return SchemaLock({});
    }
    return SchemaLock.parse(file.readAsStringSync());
  }

  /// Parses the subset of YAML written by [serialize].
  static SchemaLock parse(String content) {
    final entries = <String, SchemaLockEntry>{};
    String? key;
    var fields = <String, String>{};
    var signatures = <String>[];

    void flush() {
      final currentKey = key;
      if (currentKey == null) {
        return;
      }
      entries[currentKey] = SchemaLockEntry(
        sourcePath: fields['source_path'] ?? '',
        hash: fields['hash'] ?? '',
        signatures: signatures,
        lastMigration: fields['last_migration'] ?? '',
      );
    }

    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      if (!line.startsWith(' ')) {
        flush();
        key = trimmed.substring(0, trimmed.length - 1);
        fields = {};
        signatures = [];
      } else if (trimmed.startsWith('- ')) {
        signatures.add(_unquote(trimmed.substring(2).trim()));
      } else {
        final colon = trimmed.indexOf(':');
        fields[trimmed.substring(0, colon)] =
            _unquote(trimmed.substring(colon + 1).trim());
      }
    }
    flush();
    return SchemaLock(entries);
  }

  String serialize() {
    final buffer = StringBuffer()
      ..writeln('# Declarative SQL object lock — hash of each source file.')
      ..writeln('# Managed by: melos run migrate:generate / schema:adopt');
    final keys = entries.keys.toList()..sort();
    for (final key in keys) {
      final entry = entries[key]!;
      buffer
        ..writeln()
        ..writeln('$key:')
        ..writeln('  source_path: ${entry.sourcePath}')
        ..writeln('  hash: ${entry.hash}')
        ..writeln('  signatures:');
      for (final signature in entry.signatures) {
        buffer.writeln('    - ${jsonEncode(signature)}');
      }
      buffer.writeln('  last_migration: ${entry.lastMigration}');
    }
    return buffer.toString();
  }

  void write(File file) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(serialize());
  }

  static String _unquote(String value) {
    if (value.startsWith('"')) {
      return jsonDecode(value) as String;
    }
    return value;
  }
}
