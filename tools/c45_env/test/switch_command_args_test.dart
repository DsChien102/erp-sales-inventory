import 'dart:io';

import 'package:test/test.dart';
import 'package:c45_env/manifest.dart';
import 'package:c45_env/switch_command_args.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;
  late EnvManifest manifest;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('c45_switch_args_');
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
    manifest = EnvManifest.load(root);
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('empty args is status only', () {
    final parsed = SwitchCommandArgs.parse([], manifest);
    expect(parsed.statusOnly, isTrue);
  });

  test('flags only without changes is status only', () {
    final parsed = SwitchCommandArgs.parse(['--help'], manifest);
    expect(parsed.statusOnly, isTrue);
  });

  test('positional profile only', () {
    final parsed = SwitchCommandArgs.parse(['acme'], manifest);
    expect(parsed.statusOnly, isFalse);
    expect(parsed.profileId, 'acme');
    expect(parsed.environmentId, isNull);
  });

  test('positional profile and environment', () {
    final parsed = SwitchCommandArgs.parse(['acme', 'staging'], manifest);
    expect(parsed.profileId, 'acme');
    expect(parsed.environmentId, 'staging');
  });

  test('flag-based profile and environment', () {
    final parsed = SwitchCommandArgs.parse(
      ['--profile', 'acme', '--env', 'staging', '--target', 'erp'],
      manifest,
    );
    expect(parsed.profileId, 'acme');
    expect(parsed.environmentId, 'staging');
    expect(parsed.targetId, 'erp');
    expect(parsed.skipLink, isFalse);
  });

  test('target flag alone triggers sync scope', () {
    final parsed = SwitchCommandArgs.parse(['--target', 'erp'], manifest);
    expect(parsed.statusOnly, isFalse);
    expect(parsed.targetId, 'erp');
  });

  test('skip-link flag', () {
    final parsed = SwitchCommandArgs.parse(['acme', '--skip-link'], manifest);
    expect(parsed.skipLink, isTrue);
    expect(parsed.profileId, 'acme');
  });
}
