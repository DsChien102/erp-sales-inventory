import 'dart:io';

import 'package:test/test.dart';
import 'package:c45_env/workspace_manifest.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('c45_workspace_');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('loads environments from workspace file without profiles block', () {
    writeTestWorkspace(
      root,
      defaultEnvironment: 'local',
      environmentIds: ['local', 'staging'],
    );
    final workspace = WorkspaceManifest.load(root);
    expect(workspace.defaultEnvironmentId, 'local');
    expect(workspace.environments.keys, containsAll(['local', 'staging']));
    expect(workspace.toJson().containsKey('profiles'), isFalse);
  });

  test('write round-trips environments and doctor', () {
    writeTestWorkspace(root);
    final workspace = WorkspaceManifest.load(root);
    final updated = WorkspaceManifest(
      version: workspace.version,
      defaultEnvironmentId: workspace.defaultEnvironmentId,
      scan: workspace.scan,
      environments: workspace.environments,
      rootDir: workspace.rootDir,
      file: workspace.file,
      doctor: workspace.doctor,
    );
    updated.write();
    final reloaded = WorkspaceManifest.load(root);
    expect(reloaded.environments.keys, contains('local'));
    expect(reloaded.doctor.alignHosts, isNotEmpty);
    expect(reloaded.toJson().containsKey('profiles'), isFalse);
  });
}
