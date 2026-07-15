import 'dart:io';

import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/secrets_loader.dart';
import 'package:vet45_env/tui/services_bridge.dart';
import 'package:vet45_env/tui/shell.dart';

import '../test_manifest_fixture.dart';

void main() {
  late Directory root;
  late TuiServicesBridge bridge;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_tui_shell_');
    Directory('${root.path}/config/secrets').createSync(recursive: true);
    Directory('${root.path}/apps/erp').createSync(recursive: true);
    Directory('${root.path}/apps/messaging_worker').createSync(recursive: true);
    File('${root.path}/config/environments.json').writeAsStringSync(
      manifestWithEnv('''
{
  "local": {
    "description": "test local",
    "supabaseSource": "secrets",
    "targets": {
      "erp": {
        "flavor": "development",
        "envFile": "apps/erp/.env",
        "appEnv": "development"
      },
      "worker": {
        "envFile": "apps/messaging_worker/.env"
      }
    }
  },
  "staging": {
    "description": "staging",
    "supabaseSource": "secrets",
    "targets": {
      "erp": {
        "flavor": "staging",
        "envFile": "apps/erp/.env.staging",
        "appEnv": "staging"
      },
      "worker": {
        "envFile": "apps/messaging_worker/.env.staging"
      }
    }
  }
}
'''),
    );
    File('${root.path}/config/profiles.json').writeAsStringSync('''
{
  "defaultProfile": "default",
  "profiles": {
    "default": {
      "description": "Default",
      "secretsRoot": "config/secrets"
    },
    "acme": {
      "description": "Acme",
      "secretsRoot": "config/profiles/acme/secrets"
    }
  }
}
''');
    writeDotEnv(
      File('${root.path}/config/secrets/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon',
        'SUPABASE_SERVICE_ROLE_KEY': 'service',
        'WORKER_TICK_SECRET': 'tick',
      },
    );
    // staging only as example — must not appear in TUI env list
    File('${root.path}/config/secrets/staging.env.example')
        .writeAsStringSync('SUPABASE_URL=\n');
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

  test('shell renders profiles and environments', () async {
    await testNocterm(
      'render panels',
      (tester) async {
        await tester.pumpComponent(Vet45TuiShell(bridge: bridge));
        expect(tester.terminalState, containsText('Profiles'));
        expect(tester.terminalState, containsText('Environments'));
        expect(tester.terminalState, containsText('default'));
        expect(tester.terminalState, containsText('local'));
        expect(
          tester.terminalState.containsText('staging'),
          isFalse,
          reason: 'staging.env.example must not list staging',
        );
        expect(tester.terminalState, containsText('Log'));
      },
      size: const Size(100, 40),
    );
  });

  test('arrow down moves cursor then tab cycles focus', () async {
    await testNocterm(
      'keymap',
      (tester) async {
        await tester.pumpComponent(Vet45TuiShell(bridge: bridge));
        await tester.sendArrowDown();
        await tester.pump();
        await tester.sendTab();
        await tester.pump();
        expect(tester.terminalState, containsText('* Environments'));
      },
      size: const Size(100, 40),
    );
  });
}
