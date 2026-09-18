import 'dart:io';

import 'package:test/test.dart';

void main() {
  late List<File> activeFiles;

  setUpAll(() {
    final root = _findRepoRoot();
    final drafts = Directory('${root.path}/supabase/migrations/_drafts');
    activeFiles =
        drafts.listSync().whereType<File>().where((file) => file.path.endsWith('.sql')).toList()
          ..sort((a, b) => a.path.compareTo(b.path));
  });

  test('no active IAM SQL drafts remain after in-place promote merge', () {
    expect(
      activeFiles.map((file) => file.uri.pathSegments.last),
      isEmpty,
    );
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
