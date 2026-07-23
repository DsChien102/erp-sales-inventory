import 'dart:io';

import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/secrets_loader.dart';
import 'package:vet45_env/tui/services_bridge.dart';
import 'package:vet45_env/tui/shell.dart';
import 'package:vet45_env/tui/vet45_tui_theme.dart';

import '../test_manifest_fixture.dart';

void main() {
  late Directory root;
  late TuiServicesBridge bridge;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_tui_shell_');
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
      profileIds: ['default', 'acme'],
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
    // staging only as example — must not appear in TUI env list
    File('${root.path}/.vet45/profiles/default/staging.env.example')
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

  Component themedShell() => TuiTheme(
        data: Vet45TuiTheme.dark,
        child: Vet45TuiShell(bridge: bridge),
      );

  test('shell renders profiles and environments', () async {
    await testNocterm(
      'render panels',
      (tester) async {
        await tester.pumpComponent(themedShell());
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
        await tester.pumpComponent(themedShell());
        await tester.sendArrowDown();
        await tester.pump();
        await tester.sendTab();
        await tester.pump();
        expect(tester.terminalState, containsText('* Environments'));
      },
      size: const Size(100, 40),
    );
  });

  test('key 2 switches to Run mode with Sessions sidebar', () async {
    await testNocterm(
      'run mode',
      (tester) async {
        await tester.pumpComponent(themedShell());
        await tester.enterText('2');
        await tester.pump();
        // Narrow flex column truncates the Sessions title (e.g. "Ses…").
        expect(tester.terminalState, containsText('Ses'));
        expect(tester.terminalState, containsText('Terminal'));
        expect(tester.terminalState, containsText('n = new'));
        // Panels must fill their flex slots (no shrink-wrap gap between them).
        final dump = tester.terminalState.getText();
        final topBorders = dump
            .split('\n')
            .where((l) => l.contains('╭') && l.contains('Terminal'))
            .toList();
        expect(topBorders.isNotEmpty, isTrue, reason: dump);
        final line = topBorders.first;
        // After Sessions box there should be at most a 1-col spacer before Terminal.
        final sessionsEnd = line.indexOf('╮');
        final terminalStart = line.indexOf('╭─ Terminal');
        expect(sessionsEnd, greaterThan(0));
        expect(terminalStart, greaterThan(sessionsEnd));
        expect(
          terminalStart - sessionsEnd,
          lessThanOrEqualTo(3),
          reason: 'gap between Sessions and Terminal: "$line"',
        );
        // Terminal border should reach near the right margin (flex 4 of ~100).
        final terminalEnd = line.lastIndexOf('╮');
        expect(terminalEnd, greaterThan(70), reason: line);
        expect(
          tester.terminalState.containsText('Targets'),
          isFalse,
          reason: 'Targets only after n',
        );
      },
      size: const Size(100, 40),
    );
  });

  test('key n opens new session picker with Targets', () async {
    await testNocterm(
      'new session picker',
      (tester) async {
        await tester.pumpComponent(themedShell());
        await tester.enterText('2');
        await tester.pump();
        await tester.enterText('n');
        await tester.pump();
        expect(tester.terminalState, containsText('Targets'));
        expect(tester.terminalState, containsText('Actions'));
        expect(tester.terminalState, containsText('erp'));
      },
      size: const Size(100, 40),
    );
  });

  test('key a opens extra args prompt in new session picker', () async {
    await testNocterm(
      'extra args prompt',
      (tester) async {
        await tester.pumpComponent(themedShell());
        await tester.enterText('2');
        await tester.pump();
        await tester.enterText('n');
        await tester.pump();
        await tester.sendTab(); // Targets -> Actions
        await tester.pump();
        await tester.enterText('a');
        await tester.pump();
        expect(tester.terminalState, containsText('Extra args'));
        expect(tester.terminalState, containsText('Enter run'));
        // Resolved flutter command preview (templates may leave empty tokens).
        expect(tester.terminalState, containsText('flutter'));
        await tester.enterText('--device');
        await tester.pump();
        expect(tester.terminalState, containsText('--device'));
        await tester.sendEscape();
        await tester.pump();
        expect(
          tester.terminalState.containsText('Extra args'),
          isFalse,
          reason: 'Esc cancels args popup',
        );
        expect(tester.terminalState, containsText('a +args'));
      },
      size: const Size(100, 40),
    );
  });
}
