import 'dart:io';

import 'manifest.dart';
import 'profile_discovery.dart';
import 'profile_registry.dart';
import 'repo_root.dart';
import 'target_discovery.dart';
import 'workspace_manifest.dart';

class ConfigInitResult {
  ConfigInitResult({
    required this.profileId,
    required this.created,
    required this.skipped,
  });

  final String profileId;
  final List<String> created;
  final List<String> skipped;

  bool get alreadyInitialized => created.isEmpty && skipped.isNotEmpty;
}

/// Scaffolds a local profile under `.vet45/profiles/` from [.vet45/templates/].
class ConfigInitService {
  ConfigInitService({Directory? repoRoot})
      : repoRoot = repoRoot ?? Directory(findRepoRoot());

  final Directory repoRoot;

  bool get hasWorkspace =>
      WorkspaceManifest.workspaceFile(repoRoot).existsSync();

  Directory get templatesDir => ProfileDiscovery.templatesDir(repoRoot);

  bool get hasTemplates => templatesDir.existsSync();

  /// True when at least one profile directory exists under `.vet45/profiles/`.
  bool get isInitialized {
    if (!hasWorkspace) {
      return false;
    }
    return ProfileDiscovery(rootDir: repoRoot).discover().isNotEmpty;
  }

  static final _validProfileId = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');

  Future<ConfigInitResult> init(
    String profileId, {
    bool force = false,
    String? description,
  }) async {
    if (!hasWorkspace) {
      throw StateError(
        'Missing ${WorkspaceManifest.fileName} at ${repoRoot.path}. '
        'This file must be checked out from the Vet45 monorepo.',
      );
    }

    final id = profileId.trim();
    if (id.isEmpty) {
      throw StateError(
        'Usage: vet45 init <profileId> [--force]\n'
        'Example: vet45 init acme',
      );
    }
    if (!_validProfileId.hasMatch(id)) {
      throw StateError(
        'Invalid profile id "$id". Use letters, digits, _ or - '
        '(must start with a letter).',
      );
    }
    if (ProfileDiscovery.reservedNames.contains(id)) {
      throw StateError('Cannot init reserved profile id: $id');
    }

    final workspace = WorkspaceManifest.load(repoRoot);
    final discovered = TargetDiscovery(
      rootDir: repoRoot,
      scan: workspace.scan,
    ).discover();
    final collidingTarget = discovered[id];
    if (collidingTarget != null && !collidingTarget.writeEnvFile) {
      throw StateError('Cannot init reserved target/config id: $id');
    }

    if (!hasTemplates) {
      throw StateError(
        'Missing committed templates at ${templatesDir.path}. '
        'Check out .vet45/templates/ from the monorepo.',
      );
    }

    final secretsRoot = '${ProfileDiscovery.profilesRootName}/$id';
    final profileDir = Directory('${repoRoot.path}/$secretsRoot');
    profileDir.createSync(recursive: true);

    final created = <String>[];
    final skipped = <String>[];

    _copyExamples(
      fromDir: templatesDir,
      toDir: profileDir,
      relativePrefix: secretsRoot,
      force: force,
      created: created,
      skipped: skipped,
    );

    // Scaffold secrets-only target dirs (e.g. .vet45/deploy) from colocated examples.
    for (final target in discovered.values) {
      if (target.writeEnvFile || target.secretsFile == null) {
        continue;
      }
      final dirPath = _relativePath(repoRoot, target.manifestDir.path);
      final dir = Directory('${repoRoot.path}/$dirPath');
      if (!dir.existsSync()) {
        continue;
      }
      _copyExamples(
        fromDir: dir,
        toDir: dir,
        relativePrefix: dirPath,
        force: force,
        created: created,
        skipped: skipped,
        onlyEnvFiles: true,
      );
    }

    if (created.isEmpty && skipped.isEmpty && !force) {
      throw StateError(
        'No *.env.example found under ${templatesDir.path}.',
      );
    }

    final envId = tryReadActiveState(
          repoRoot,
          defaultEnvironmentId: workspace.defaultEnvironmentId,
        )?.environmentId ??
        workspace.defaultEnvironmentId;

    writeActiveState(
      repoRoot,
      ActiveState(profileId: id, environmentId: envId),
    );

    if (description != null && description.trim().isNotEmpty) {
      // Description is local-only; profiles are not registered in workspace.
      File('${profileDir.path}/.profile').writeAsStringSync(
        '${description.trim()}\n',
      );
    }

    return ConfigInitResult(
      profileId: id,
      created: created,
      skipped: skipped,
    );
  }

  void _copyExamples({
    required Directory fromDir,
    required Directory toDir,
    required String relativePrefix,
    required bool force,
    required List<String> created,
    required List<String> skipped,
    bool onlyEnvFiles = false,
  }) {
    if (!fromDir.existsSync()) {
      return;
    }
    toDir.createSync(recursive: true);
    for (final entity in fromDir.listSync(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.env.example')) {
        continue;
      }
      // Always copy the example file into the profile dir when sourcing templates.
      if (!onlyEnvFiles && fromDir.path == templatesDir.path) {
        final exampleDest = File('${toDir.path}/$name');
        if (!exampleDest.existsSync() || force) {
          exampleDest.writeAsStringSync(entity.readAsStringSync());
          if (!created.contains('$relativePrefix/$name')) {
            created.add('$relativePrefix/$name');
          }
        } else {
          skipped.add('$relativePrefix/$name');
        }
      }

      final destName = name.replaceFirst(RegExp(r'\.example$'), '');
      // auth.env is optional — init only scaffolds auth.env.example.
      // Create the real file yourself when you need SUPABASE_ACCESS_TOKEN.
      if (destName == 'auth.env') {
        continue;
      }
      final dest = File('${toDir.path}/$destName');
      final relative = '$relativePrefix/$destName';
      if (dest.existsSync() && !_shouldOverwrite(dest.path, force: force)) {
        if (!skipped.contains(relative)) {
          skipped.add(relative);
        }
        continue;
      }
      if (dest.existsSync() && _isFilledSecretEnv(dest.path)) {
        if (!skipped.contains(relative)) {
          skipped.add(relative);
        }
        continue;
      }
      dest.writeAsStringSync(entity.readAsStringSync());
      if (!created.contains(relative)) {
        created.add(relative);
      }
    }
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

  if (!ProfileDiscovery.templatesDir(repoRoot).existsSync()) {
    stderr.writeln('Missing .vet45/templates/');
    stderr.writeln('Check out .vet45/templates/*.env.example from the monorepo.');
    exit(1);
  }

  final profiles = ProfileDiscovery(rootDir: repoRoot).discover();
  if (profiles.isEmpty) {
    stderr.writeln('No local profiles under .vet45/profiles/.');
    stderr.writeln('');
    stderr.writeln('First-time setup:');
    stderr.writeln('  melos bootstrap');
    stderr.writeln('  vet45 init <profileId>');
    stderr.writeln('  # fill .vet45/profiles/<profileId>/*.env, then: vet45 sync');
    exit(1);
  }

  try {
    final workspace = WorkspaceManifest.load(repoRoot);
    readActiveState(
      repoRoot,
      defaultEnvironmentId: workspace.defaultEnvironmentId,
      knownProfileIds: profiles.keys.toSet(),
    );
  } on StateError catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}
