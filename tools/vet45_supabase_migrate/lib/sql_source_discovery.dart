import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'sql_object_parser.dart';

const modulesRelativePath = 'modules';
const moduleSqlRelativePath = 'infrastructure/supabase/sql';
const sharedSqlRelativePath = 'supabase/sql';

const objectKindDirs = <SqlObjectKind, String>{
  SqlObjectKind.function: 'functions',
  SqlObjectKind.view: 'views',
  SqlObjectKind.trigger: 'triggers',
  SqlObjectKind.policy: 'policies',
};

/// Source files violate the declarative SQL layout rules.
class SchemaSourceException implements Exception {
  const SchemaSourceException(this.problems);

  final List<String> problems;

  @override
  String toString() => 'Invalid declarative SQL sources:\n'
      '${problems.map((problem) => '  - $problem').join('\n')}';
}

/// One declarative source file defining a single SQL object (all overloads).
class SqlSource {
  const SqlSource({
    required this.kind,
    required this.relativePath,
    required this.qualifiedName,
    required this.content,
    required this.hash,
    required this.signatures,
  });

  final SqlObjectKind kind;

  /// Repo-relative path with `/` separators.
  final String relativePath;
  final String qualifiedName;

  /// File content with `\n` line endings.
  final String content;

  /// `sha256:<hex>` of [content].
  final String hash;

  /// Function: overload signatures. Trigger/policy: `"name on schema.table"`
  /// for later drops. Views: empty (drop by [qualifiedName]).
  final List<String> signatures;
}

/// Discovers declarative SQL sources under module roots and the shared root:
///
/// - `modules/<module>/infrastructure/supabase/sql/{functions,views,triggers,policies}/<name>.sql`,
///   schema must equal `<module>`.
/// - `supabase/sql/<schema>/{functions,views,triggers,policies}/<name>.sql`,
///   schema must equal `<schema>`.
class SqlSourceDiscovery {
  List<SqlSource> discover(Directory repoRoot) {
    final problems = <String>[];
    final sources = <SqlSource>[];

    for (final (root, schema) in _sqlRoots(repoRoot)) {
      for (final MapEntry(key: kind, value: dir) in objectKindDirs.entries) {
        final folder = Directory('${repoRoot.path}/$root/$dir');
        if (!folder.existsSync()) {
          continue;
        }
        final files = folder
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
        for (final file in files) {
          final source = _readSource(
            file: file,
            relativePath: '$root/$dir/${_basename(file.path)}',
            root: root,
            expectedSchema: schema,
            expectedKind: kind,
            problems: problems,
          );
          if (source != null) {
            sources.add(source);
          }
        }
      }
    }

    final pathsByName = <String, List<String>>{};
    for (final source in sources) {
      pathsByName
          .putIfAbsent(source.qualifiedName, () => [])
          .add(source.relativePath);
    }
    for (final MapEntry(key: name, value: paths) in pathsByName.entries) {
      if (paths.length > 1) {
        problems.add(
          '$name is defined in more than one file: ${paths.join(', ')}',
        );
      }
    }

    if (problems.isNotEmpty) {
      throw SchemaSourceException(problems);
    }
    return sources..sort((a, b) => a.qualifiedName.compareTo(b.qualifiedName));
  }

  /// Yields `(repo-relative sql root, expected schema)` pairs that exist.
  Iterable<(String, String)> _sqlRoots(Directory repoRoot) sync* {
    final roots = <(String, String)>[
      for (final module
          in _childDirectoryNames('${repoRoot.path}/$modulesRelativePath'))
        ('$modulesRelativePath/$module/$moduleSqlRelativePath', module),
      for (final schema
          in _childDirectoryNames('${repoRoot.path}/$sharedSqlRelativePath'))
        ('$sharedSqlRelativePath/$schema', schema),
    ];
    for (final root in roots) {
      if (Directory('${repoRoot.path}/${root.$1}').existsSync()) {
        yield root;
      }
    }
  }

  SqlSource? _readSource({
    required File file,
    required String relativePath,
    required String root,
    required String expectedSchema,
    required SqlObjectKind expectedKind,
    required List<String> problems,
  }) {
    final kindDir = objectKindDirs[expectedKind]!;
    final content = file.readAsStringSync().replaceAll('\r\n', '\n');
    final objects = parseSqlObjects(content);
    final matching =
        objects.where((object) => object.kind == expectedKind).toList();

    if (matching.isEmpty) {
      problems.add(
        '$relativePath: no create ${_kindLabel(expectedKind)} statement found',
      );
      return null;
    }
    if (matching.length != objects.length) {
      problems.add(
        '$relativePath: $kindDir/ may only define ${_kindLabel(expectedKind)}s',
      );
      return null;
    }

    final names = matching.map((object) => object.qualifiedName).toSet();
    if (names.length > 1) {
      problems.add(
        '$relativePath: one file per ${_kindLabel(expectedKind)}, '
        'found ${names.join(', ')}',
      );
      return null;
    }

    final object = matching.first;
    var valid = true;
    if (object.schema != expectedSchema) {
      problems.add(
        '$relativePath: defines ${object.qualifiedName} but sources under '
        '$root must use schema "$expectedSchema"',
      );
      valid = false;
    }
    final expectedFileName = '${object.name}.sql';
    if (_basename(file.path) != expectedFileName) {
      problems.add(
        '$relativePath: file must be named $expectedFileName after its '
        '${_kindLabel(expectedKind)}',
      );
      valid = false;
    }
    if (!valid) {
      return null;
    }

    return SqlSource(
      kind: expectedKind,
      relativePath: relativePath,
      qualifiedName: object.qualifiedName,
      content: content,
      hash: 'sha256:${sha256.convert(utf8.encode(content))}',
      signatures: switch (expectedKind) {
        SqlObjectKind.function =>
          matching.map((function) => function.signature!).toList(),
        SqlObjectKind.trigger || SqlObjectKind.policy => matching
            .map((object) => '${object.name} on ${object.table}')
            .toList(),
        SqlObjectKind.view => const [],
      },
    );
  }

  String _kindLabel(SqlObjectKind kind) => switch (kind) {
        SqlObjectKind.function => 'function',
        SqlObjectKind.view => 'view',
        SqlObjectKind.trigger => 'trigger',
        SqlObjectKind.policy => 'policy',
      };

  List<String> _childDirectoryNames(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      return const [];
    }
    return directory
        .listSync()
        .whereType<Directory>()
        .map((child) => _basename(child.path))
        .toList()
      ..sort();
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last;
}
