import 'dart:io';

/// Walks up from [start] until a directory contains `pubspec.yaml` with `name: c45`.
String findRepoRoot({String? start}) {
  var current = Directory(start ?? Directory.current.path).absolute;

  while (true) {
    final pubspec = File('${current.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      if (content.contains('name: c45')) {
        return current.path;
      }
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not find Mosaic Retail repo root from ${start ?? Directory.current.path}');
    }
    current = parent;
  }
}
