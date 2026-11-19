import 'dart:io';

import 'workspace_manifest.dart';

/// Walks up from [start] until a directory contains [c45.workspace.json].
String findRepoRoot({String? start}) {
  var current = Directory(start ?? Directory.current.path).absolute;

  while (true) {
    final workspace = WorkspaceManifest.workspaceFile(current);
    if (workspace.existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not find Mosaic Retail workspace root from ${start ?? Directory.current.path}\n'
        'Expected ${WorkspaceManifest.fileName} in a parent directory.',
      );
    }
    current = parent;
  }
}
