import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/workspace_manifest.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_workspace_');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('loads profiles and environments from workspace file', () {
    writeTestWorkspace(
      root,
      defaultEnvironment: 'development',
      environmentIds: ['development', 'local'],
    );
    final workspace = WorkspaceManifest.load(root);
    expect(workspace.defaultEnvironmentId, 'development');
    expect(workspace.environments.keys, containsAll(['development', 'local']));
    expect(workspace.profiles.defaultProfileId, 'default');
    expect(workspace.profiles.profiles['default']!.secretsRoot, 'config/secrets');
    expect(workspace.scan.include, isNotEmpty);
  });

  test('write round-trips profile entries', () {
    writeTestWorkspace(root);
    final workspace = WorkspaceManifest.load(root);
    final updatedProfiles = Map<String, ProfileDefinition>.from(
      workspace.profiles.profiles,
    );
    updatedProfiles['acme'] = ProfileDefinition(
      id: 'acme',
      description: 'Client Acme',
      secretsRoot: 'config/profiles/acme/secrets',
    );

    final updated = WorkspaceManifest(
      version: workspace.version,
      defaultEnvironmentId: workspace.defaultEnvironmentId,
      scan: workspace.scan,
      profiles: ProfileRegistry(
        defaultProfileId: workspace.profiles.defaultProfileId,
        profiles: updatedProfiles,
        rootDir: workspace.rootDir,
      ),
      environments: workspace.environments,
      rootDir: workspace.rootDir,
      file: workspace.file,
    );
    updated.write();

    final reloaded = WorkspaceManifest.load(root);
    expect(reloaded.profiles.profiles.containsKey('acme'), isTrue);
    expect(
      reloaded.profiles.getProfile('acme').secretsRoot,
      'config/profiles/acme/secrets',
    );
    // Ensure JSON still has expected shape.
    final raw =
        jsonDecode(reloaded.file.readAsStringSync()) as Map<String, dynamic>;
    expect(raw['profiles'], contains('entries'));
  });
}
