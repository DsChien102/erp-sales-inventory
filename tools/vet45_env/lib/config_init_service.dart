import 'dart:io';

import 'repo_root.dart';
import 'target_discovery.dart';
import 'workspace_manifest.dart';

class ConfigInitResult {
  ConfigInitResult({
    required this.created,
    required this.skipped,
  });

  final List<String> created;
  final List<String> skipped;

  bool get alreadyInitialized => created.isEmpty && skipped.isNotEmpty;
}

/// Scaffolds local secrets under `config/secrets/` from bundled templates.
///
/// Workspace/target manifests are committed — init no longer copies them.
class ConfigInitService {
  ConfigInitService({Directory? repoRoot})
      : repoRoot = repoRoot ?? Directory(findRepoRoot());

  final Directory repoRoot;

  static String templatesDir(Directory root) =>
      '${root.path}/tools/vet45_env/templates/config';

  bool get hasWorkspace =>
      WorkspaceManifest.workspaceFile(repoRoot).existsSync();

  bool get isInitialized =>
      Directory('${repoRoot.path}/config/secrets').existsSync();

  Future<ConfigInitResult> init({bool force = false}) async {
    if (!hasWorkspace) {
      throw StateError(
        'Missing ${WorkspaceManifest.fileName} at ${repoRoot.path}. '
        'This file must be checked out from the Vet45 monorepo.',
      );
    }

    final templates = Directory(templatesDir(repoRoot));
    if (!templates.existsSync()) {
      throw StateError(
        'Missing config templates at ${templates.path}. '
        'Run melos bootstrap from the Vet45 monorepo root.',
      );
    }

    if (isInitialized && !force) {
      throw StateError(
        'Secrets already initialized at ${repoRoot.path}/config/secrets. '
        'Use --force to refresh scaffold files '
        '(never overwrites filled *.env secrets).',
      );
    }

    final created = <String>[];
    final skipped = <String>[];

    await for (final entity
        in templates.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final relative = _relativePath(templates.path, entity.path);
      // Only scaffold secrets templates (manifests are committed at repo root).
      if (!relative.startsWith('secrets${Platform.pathSeparator}') &&
          !relative.startsWith('secrets/') &&
          relative != 'README.md' &&
          !relative.startsWith('profiles${Platform.pathSeparator}') &&
          !relative.startsWith('profiles/')) {
        continue;
      }
      final dest = File('${repoRoot.path}/config/$relative');
      if (dest.existsSync() && !_shouldOverwrite(dest.path, force: force)) {
        skipped.add(relative);
        continue;
      }
      dest.parent.createSync(recursive: true);
      await dest.writeAsBytes(await entity.readAsBytes());
      created.add(relative);
    }

    return ConfigInitResult(created: created, skipped: skipped);
  }

  static bool _shouldOverwrite(String destPath, {required bool force}) {
    if (!force) {
      return false;
    }
    if (_isFilledSecretEnv(destPath)) {
      return false;
    }
    return true;
  }

  static bool _isFilledSecretEnv(String path) {
    if (!path.endsWith('.env')) {
      return false;
    }
    if (path.endsWith('.env.example')) {
      return false;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return false;
    }
    final content = file.readAsStringSync().trim();
    if (content.isEmpty) {
      return false;
    }
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final eq = trimmed.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      final value = trimmed.substring(eq + 1).trim();
      if (value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static String _relativePath(String root, String filePath) {
    final normalizedRoot = root.endsWith(Platform.pathSeparator)
        ? root
        : '$root${Platform.pathSeparator}';
    if (!filePath.startsWith(normalizedRoot)) {
      return filePath;
    }
    return filePath.substring(normalizedRoot.length);
  }
}

void requireConfigInitialized(Directory repoRoot) {
  final workspaceFile = WorkspaceManifest.workspaceFile(repoRoot);
  if (!workspaceFile.existsSync()) {
    stderr.writeln('Missing ${WorkspaceManifest.fileName} at ${repoRoot.path}');
    stderr.writeln('Check out the Vet45 monorepo (this file is committed).');
    exit(1);
  }

  try {
    final workspace = WorkspaceManifest.load(repoRoot);
    TargetDiscovery(rootDir: repoRoot, scan: workspace.scan).discover();
  } on Object catch (e) {
    stderr.writeln('Vet45 workspace/target discovery failed: $e');
    exit(1);
  }

  if (!Directory('${repoRoot.path}/config/secrets').existsSync()) {
    stderr.writeln('Vet45 secrets are not initialized.');
    stderr.writeln('');
    stderr.writeln('First-time setup:');
    stderr.writeln('  melos bootstrap');
    stderr.writeln('  melos run env:init');
    stderr.writeln('');
    stderr.writeln('Then copy and fill secrets, e.g.:');
    stderr.writeln(
      '  cp config/secrets/development.env.example config/secrets/development.env',
    );
    exit(1);
  }
}
