import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/secrets_loader.dart';
import 'package:vet45_env/tui/services_bridge.dart';

import '../test_manifest_fixture.dart';

void main() {
  late Directory root;
  late TuiServicesBridge bridge;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_action_search_');
    writeTestWorkspace(
      root,
      environmentIds: ['local'],
      erpEnvOverrides: {
        'local': {
          'envFile': '.env',
          'flavor': 'development',
          'appEnv': 'development',
        },
      },
      workerEnvOverrides: {
        'local': {'envFile': '.env'},
      },
    );
    Directory('${root.path}/apps/erp').createSync(recursive: true);
    Directory('${root.path}/apps/messaging_worker').createSync(recursive: true);
    writeDotEnv(
      File('${root.path}/.vet45/profiles/default/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon',
        'SUPABASE_SERVICE_ROLE_KEY': 'service',
        'WORKER_TICK_SECRET': 'tick',
      },
    );
    writeActiveState(
      root,
      ActiveState(profileId: 'default', environmentId: 'local'),
    );
    bridge = TuiServicesBridge(manifest: EnvManifest.load(root));
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('searchActions empty query returns all actions', () {
    final all = bridge.allRunnableActions();
    expect(all, isNotEmpty);
    expect(bridge.searchActions('').length, all.length);
    expect(bridge.searchActions('   ').length, all.length);
    expect(all.any((h) => h.label == 'erp/debug'), isTrue);
  });

  test('searchActions filters by substring case-insensitive', () {
    final hits = bridge.searchActions('DeBuG');
    expect(hits, isNotEmpty);
    expect(hits.every((h) => h.label.toLowerCase().contains('debug')), isTrue);
    expect(hits.any((h) => h.targetId == 'erp'), isTrue);
  });

  test('searchActions can match target id', () {
    final hits = bridge.searchActions('worker');
    expect(hits, isNotEmpty);
    expect(hits.every((h) => h.targetId == 'worker'), isTrue);
  });
}
