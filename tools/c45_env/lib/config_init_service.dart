import 'dart:io';

import 'example_generator.dart';
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

/// Scaffolds a local profile under `.c45/profiles/` by generating examples
/// from aggregate [c45.target.json] keys (no `.c45/templates/`).
class ConfigInitService {
  ConfigInitService({Directory? repoRoot})
    : repoRoot = repoRoot ?? Directory(findRepoRoot());

  final Directory repoRoot;

  bool get hasWorkspace =>
      WorkspaceManifest.workspaceFile(repoRoot).existsSync();

  /// True when at least one profile directory exists under `.c45/profiles/`.
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
        'This file must be checked out from the Mosaic Retail monorepo.',
      );
    }

    final id = profileId.trim();
    if (id.isEmpty) {
      throw StateError(
        'Usage: c45 init <profileId> [--force]\n'
        'Example: c45 init acme',
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

    final secretsRoot = '${ProfileDiscovery.profilesRootName}/$id';
    final profileDir = Directory('${repoRoot.path}/$secretsRoot');
    profileDir.createSync(recursive: true);

    final generator = ExampleGenerator(
      repoRoot: repoRoot,
      workspace: workspace,
      targets: discovered,
    );
    final writeResult = generator.writeExamples(
      profileDir: profileDir,
      relativeProfilePrefix: secretsRoot,
      force: force,
      forceExamples: true,
      writeEnvCopies: true,
    );

    if (writeResult.created.isEmpty && writeResult.skipped.isEmpty && !force) {
      throw StateError('Failed to generate env examples for profile "$id".');
    }

    final envId =
        tryReadActiveState(
          repoRoot,
          defaultEnvironmentId: workspace.defaultEnvironmentId,
        )?.environmentId ??
        workspace.defaultEnvironmentId;

    writeActiveState(
      repoRoot,
      ActiveState(profileId: id, environmentId: envId),
    );

    if (description != null && description.trim().isNotEmpty) {
      File(
        '${profileDir.path}/.profile',
      ).writeAsStringSync('${description.trim()}\n');
    }

    return ConfigInitResult(
      profileId: id,
      created: writeResult.created,
      skipped: writeResult.skipped,
    );
  }
}

void requireConfigInitialized(Directory repoRoot) {
  final workspaceFile = WorkspaceManifest.workspaceFile(repoRoot);
  if (!workspaceFile.existsSync()) {
    stderr.writeln('Missing ${WorkspaceManifest.fileName} at ${repoRoot.path}');
    stderr.writeln('Check out the Mosaic Retail monorepo (this file is committed).');
    exit(1);
  }

  try {
    final workspace = WorkspaceManifest.load(repoRoot);
    TargetDiscovery(rootDir: repoRoot, scan: workspace.scan).discover();
  } on Object catch (e) {
    stderr.writeln('Mosaic Retail workspace/target discovery failed: $e');
    exit(1);
  }

  final profiles = ProfileDiscovery(rootDir: repoRoot).discover();
  if (profiles.isEmpty) {
    stderr.writeln('No local profiles under .c45/profiles/.');
    stderr.writeln('');
    stderr.writeln('First-time setup:');
    stderr.writeln('  melos bootstrap');
    stderr.writeln('  c45 init <profileId>');
    stderr.writeln(
      '  # fill .c45/profiles/<profileId>/*.env, then: c45 sync',
    );
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
