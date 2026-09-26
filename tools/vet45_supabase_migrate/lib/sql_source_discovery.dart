import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'sql_object_parser.dart';

const modulesRelativePath = 'modules';
const moduleSqlRelativePath = 'infrastructure/supabase/sql';
const sharedSqlRelativePath = 'supabase/sql';

/// Source files violate the declarative SQL layout rules.
class SchemaSourceException implements Exception {
  const SchemaSourceException(this.problems);

  final List<String> problems;

  @override
  String toString() => 'Invalid declarative SQL sources:\n'
      '${problems.map((problem) => '  - $problem').join('\n')}';
}

/// One declarative source file defining every overload of a function.
class SqlSource {
  const SqlSource({
    required this.relativePath,
    required this.qualifiedName,
    required this.content,
    required this.hash,
    required this.signatures,
  });

  /// Repo-relative path with `/` separators.
  final String relativePath;
  final String qualifiedName;

  /// File content with `\n` line endings.
  final String content;

  /// `sha256:<hex>` of [content].
  final String hash;
  final List<String> signatures;
}

/// Discovers function sources under module roots and the shared root:
///
/// - `modules/<module>/infrastructure/supabase/sql/functions/<name>.sql`,
///   schema must equal `<module>`.
/// - `supabase/sql/<schema>/functions/<name>.sql`, schema must equal `<schema>`.
class SqlSourceDiscovery {
  List<SqlSource> discover(Directory repoRoot) {
    final problems = <String>[];
    final sources = <SqlSource>[];

    for (final (root, schema) in _functionRoots(repoRoot)) {
      final files = Directory('${repoRoot.path}/$root/functions')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.sql'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in files) {
        final source = _readSource(
          file: file,
          relativePath: '$root/functions/${_basename(file.path)}',
          root: root,
          expectedSchema: schema,
          problems: problems,
        );
        if (source != null) {
          sources.add(source);
        }
      }
    }

    final pathsByName = <String, List<String>>{};
    for (final source in sources) {
      pathsByName.putIfAbsent(source.qualifiedName, () => []).add(source.relativePath);
    }
    for (final MapEntry(key: name, value: paths) in pathsByName.entries) {
      if (paths.length > 1) {
        problems.add('$name is defined in more than one file: ${paths.join(', ')}');
      }
    }

    if (problems.isNotEmpty) {
      throw SchemaSourceException(problems);
    }
    return sources..sort((a, b) => a.qualifiedName.compareTo(b.qualifiedName));
  }

  /// Yields `(repo-relative sql root, expected schema)` pairs that have a
  /// `functions/` folder.
  Iterable<(String, String)> _functionRoots(Directory repoRoot) sync* {
    final roots = <(String, String)>[
      for (final module in _childDirectoryNames('${repoRoot.path}/$modulesRelativePath'))
        ('$modulesRelativePath/$module/$moduleSqlRelativePath', module),
      for (final schema in _childDirectoryNames('${repoRoot.path}/$sharedSqlRelativePath'))
        ('$sharedSqlRelativePath/$schema', schema),
    ];
    for (final root in roots) {
      if (Directory('${repoRoot.path}/${root.$1}/functions').existsSync()) {
        yield root;
      }
    }
  }

  SqlSource? _readSource({
    required File file,
    required String relativePath,
    required String root,
    required String expectedSchema,
    required List<String> problems,
  }) {
    final content = file.readAsStringSync().replaceAll('\r\n', '\n');
    final objects = parseSqlObjects(content);
    final functions =
        objects.where((object) => object.kind == SqlObjectKind.function).toList();

    if (functions.isEmpty) {
      problems.add('$relativePath: no create function statement found');
      return null;
    }
    if (functions.length != objects.length) {
      problems.add('$relativePath: functions/ may only define functions');
      return null;
    }

    final names = functions.map((function) => function.qualifiedName).toSet();
    if (names.length > 1) {
      problems.add(
        '$relativePath: one file per function, found ${names.join(', ')}',
      );
      return null;
    }

    final function = functions.first;
    var valid = true;
    if (function.schema != expectedSchema) {
      problems.add(
        '$relativePath: defines ${function.qualifiedName} but sources under '
        '$root must use schema "$expectedSchema"',
      );
      valid = false;
    }
    final expectedFileName = '${function.name}.sql';
    if (_basename(file.path) != expectedFileName) {
      problems.add(
        '$relativePath: file must be named $expectedFileName after its function',
      );
      valid = false;
    }
    if (!valid) {
      return null;
    }

    return SqlSource(
      relativePath: relativePath,
      qualifiedName: function.qualifiedName,
      content: content,
      hash: 'sha256:${sha256.convert(utf8.encode(content))}',
      signatures: functions.map((function) => function.signature!).toList(),
    );
  }

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
