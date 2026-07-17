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

/// Ensures local `*.env` files exist by copying committed `*.env.example`.
class ConfigInitService {
  ConfigInitService({Directory? repoRoot})
      : repoRoot = repoRoot ?? Directory(findRepoRoot());

  final Directory repoRoot;

  bool get hasWorkspace =>
      WorkspaceManifest.workspaceFile(repoRoot).existsSync();

  bool get isInitialized {
    if (!hasWorkspace) {
      return false;
    }
    final workspace = WorkspaceManifest.load(repoRoot);
    final defaultProfile = workspace.profiles.getProfile(
      workspace.profiles.defaultProfileId,
    );
    return defaultProfile.secretsDirectory(repoRoot).existsSync();
  }

  Future<ConfigInitResult> init({bool force = false}) async {
    if (!hasWorkspace) {
      throw StateError(
        'Missing ${WorkspaceManifest.fileName} at ${repoRoot.path}. '
        'This file must be checked out from the Vet45 monorepo.',
      );
    }

    final workspace = WorkspaceManifest.load(repoRoot);
    final defaultProfile = workspace.profiles.getProfile(
      workspace.profiles.defaultProfileId,
    );
    final defaultDir = defaultProfile.secretsDirectory(repoRoot);
    if (!defaultDir.existsSync()) {
      throw StateError(
        'Missing committed profile examples at ${defaultDir.path}. '
        'Check out ${defaultProfile.secretsRoot}/*.env.example from the monorepo.',
      );
    }

    final dirs = <String>{};
    for (final profile in workspace.profiles.profiles.values) {
      dirs.add(profile.secretsRoot);
    }
    final discovered = TargetDiscovery(
      rootDir: repoRoot,
      scan: workspace.scan,
    ).discover();
    for (final target in discovered.values) {
      if (!target.writeEnvFile && target.secretsFile != null) {
        final relative = _relativePath(
          repoRoot,
          target.manifestDir.path,
        );
        dirs.add(relative);
      }
    }

    final created = <String>[];
    final skipped = <String>[];

    for (final dirPath in dirs) {
      final dir = Directory('${repoRoot.path}/$dirPath');
      if (!dir.existsSync()) {
        continue;
      }
      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        final name = entity.uri.pathSegments.last;
        if (!name.endsWith('.env.example')) {
          continue;
        }
        final destName = name.replaceFirst(RegExp(r'\.example$'), '');
        final dest = File('${dir.path}/$destName');
        final relative = '$dirPath/$destName';
        if (dest.existsSync() && !_shouldOverwrite(dest.path, force: force)) {
          skipped.add(relative);
          continue;
        }
        if (dest.existsSync() && _isFilledSecretEnv(dest.path)) {
          skipped.add(relative);
          continue;
        }
        dest.writeAsStringSync(entity.readAsStringSync());
        created.add(relative);
      }
    }

    if (created.isEmpty && skipped.isEmpty && !force) {
      throw StateError(
        'No *.env.example found under profile secrets roots or '
        'secrets-only target directories.',
      );
    }

    return ConfigInitResult(created: created, skipped: skipped);
  }

  static String _relativePath(Directory root, String absolutePath) {
    final rootPath = root.path.endsWith(Platform.pathSeparator)
        ? root.path
        : '${root.path}${Platform.pathSeparator}';
    if (absolutePath.startsWith(rootPath)) {
      return absolutePath.substring(rootPath.length).replaceAll('\\', '/');
    }
    return absolutePath.replaceAll('\\', '/');
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

  final workspace = WorkspaceManifest.load(repoRoot);
  final defaultProfile = workspace.profiles.getProfile(
    workspace.profiles.defaultProfileId,
  );
  final defaultDir = defaultProfile.secretsDirectory(repoRoot);
  if (!defaultDir.existsSync()) {
    stderr.writeln('Missing ${defaultProfile.secretsRoot}/ profile directory.');
    stderr.writeln('');
    stderr.writeln('First-time setup:');
    stderr.writeln('  melos bootstrap');
    stderr.writeln('  vet45 init');
    stderr.writeln('  # fill secrets, then: vet45 sync');
    exit(1);
  }
}
