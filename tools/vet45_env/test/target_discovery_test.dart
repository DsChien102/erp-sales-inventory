import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/target_discovery.dart';
import 'package:vet45_env/target_manifest.dart';
import 'package:vet45_env/workspace_manifest.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_discovery_');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('discovers targets under apps and config', () {
    writeTestWorkspace(root, includeAdmin: true);
    final workspace = WorkspaceManifest.load(root);
    final targets = TargetDiscovery(
      rootDir: root,
      scan: workspace.scan,
    ).discover();

    expect(targets.keys, containsAll(['erp', 'admin', 'worker', 'deploy']));
    expect(targets['erp']!.manifestDir.path, endsWith('apps/erp'));
  });

  test('resolves envFile relative to target manifest dir', () {
    writeTestWorkspace(root);
    final manifest = EnvManifest.load(root);
    final erpEnv = manifest.getEnvironment('local').erp!.envFile!;
    expect(erpEnv.path.replaceAll('\\', '/'), endsWith('apps/erp/.env'));
  });

  test('resolves deploy secretsFile relative to target dir', () {
    writeTestWorkspace(root);
    final manifest = EnvManifest.load(root);
    expect(
      manifest.deploySecretsFile.path.replaceAll('\\', '/'),
      endsWith('config/deploy/deploy.env'),
    );
  });

  test('fails when no targets found', () {
    writeTestWorkspace(
      root,
      includeErp: false,
      includeWorker: false,
      includeDeploy: false,
    );
    final workspace = WorkspaceManifest.load(root);
    expect(
      () => TargetDiscovery(rootDir: root, scan: workspace.scan).discover(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains(TargetManifest.fileName),
        ),
      ),
    );
  });

  test('target without binding for env is omitted from that environment', () {
    writeTestWorkspace(
      root,
      environmentIds: ['local', 'staging'],
      erpEnvOverrides: {
        'local': {
          'envFile': '.env',
          'flavor': 'development',
          'appEnv': 'development',
        },
        // no staging binding for erp — omit from erp environments map
      },
    );
    // Rewrite erp target to only bind local.
    File('${root.path}/apps/erp/vet45.target.json').writeAsStringSync('''
{
  "version": 1,
  "id": "erp",
  "description": "Flutter ERP",
  "keys": [
    { "name": "SUPABASE_ANON_KEY", "required": true }
  ],
  "environments": {
    "local": { "envFile": ".env", "flavor": "development", "appEnv": "development" }
  }
}
''');
    // Worker still binds both.
    final manifest = EnvManifest.load(root);
    expect(manifest.getEnvironment('local').bindings.containsKey('erp'), isTrue);
    expect(
      manifest.getEnvironment('staging').bindings.containsKey('erp'),
      isFalse,
    );
    expect(
      manifest.getEnvironment('staging').bindings.containsKey('worker'),
      isTrue,
    );
  });
}
