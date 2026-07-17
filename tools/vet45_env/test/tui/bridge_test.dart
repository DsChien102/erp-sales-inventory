import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/secrets_loader.dart';
import 'package:vet45_env/tui/services_bridge.dart';

import '../test_manifest_fixture.dart';

void main() {
  late Directory root;
  late EnvManifest manifest;
  late TuiServicesBridge bridge;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_tui_bridge_');
    writeTestWorkspace(
      root,
      environmentIds: ['local', 'staging'],
      erpEnvOverrides: {
        'local': {
          'envFile': '.env',
          'flavor': 'development',
          'appEnv': 'development',
        },
        'staging': {
          'envFile': '.env.staging',
          'flavor': 'staging',
          'appEnv': 'staging',
        },
      },
      workerEnvOverrides: {
        'local': {'envFile': '.env'},
        'staging': {'envFile': '.env.staging'},
      },
    );
    Directory('${root.path}/apps/erp').createSync(recursive: true);
    Directory('${root.path}/apps/messaging_worker').createSync(recursive: true);
    writeDotEnv(
      File('${root.path}/config/default/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon-test',
        'SUPABASE_SERVICE_ROLE_KEY': 'service-test',
        'WORKER_TICK_SECRET': 'tick-test',
      },
    );
    writeDotEnv(
      File('${root.path}/config/default/staging.env'),
      {
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_ANON_KEY': 'staging-anon',
        'SUPABASE_SERVICE_ROLE_KEY': 'staging-service',
        'WORKER_TICK_SECRET': 'staging-tick',
      },
    );
    writeActiveState(
      root,
      ActiveState(profileId: 'default', environmentId: 'local'),
    );
    manifest = EnvManifest.load(root);
    bridge = TuiServicesBridge(manifest: manifest);
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('environmentIds only includes envs with real secrets files', () {
    File('${root.path}/config/default/production.env.example')
        .writeAsStringSync('SUPABASE_URL=\n');
    expect(bridge.environmentIds(profileId: 'default'), ['local', 'staging']);
    expect(
      bridge.environmentIds(profileId: 'default'),
      isNot(contains('production')),
    );
  });

  test('switchWorkspace writes erp env and returns log lines', () async {
    final result = await bridge.switchWorkspace(
      profileId: 'default',
      environmentId: 'staging',
      skipLink: true,
    );

    expect(result.ok, isTrue, reason: result.lines.join('\n'));
    expect(result.activeEnvironment, 'staging');
    expect(result.lines.any((l) => l.contains('Active:')), isTrue);
    expect(result.lines.any((l) => l.contains('OK') || l.contains('Synced')), isTrue);
    expect(File('${root.path}/apps/erp/.env.staging').existsSync(), isTrue);
  });

  test('doctor returns check lines', () async {
    final result = await bridge.doctor(targetId: 'erp');
    expect(result.lines.any((l) => l.startsWith('Profile:')), isTrue);
    expect(result.lines.any((l) => l.contains('[')), isTrue);
  });

  test('refresh reloads active state', () {
    final result = bridge.refresh();
    expect(result.ok, isTrue);
    expect(result.activeProfile, 'default');
    expect(result.activeEnvironment, 'local');
  });
}
