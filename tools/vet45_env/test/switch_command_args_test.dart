import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/switch_command_args.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;
  late EnvManifest manifest;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_switch_args_');
    Directory('${root.path}/config/secrets').createSync(recursive: true);
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
    "description": "test staging",
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
      "description": "Acme client",
      "secretsRoot": "config/profiles/acme/secrets"
    }
  }
}
''');
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
