import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/config_init_service.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/secrets_loader.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_config_init_');
    writeTestWorkspace(
      root,
      profileIds: const [],
      writeActive: false,
    );
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('init requires profile id and scaffolds from templates', () async {
    final service = ConfigInitService(repoRoot: root);
    expect(service.hasWorkspace, isTrue);
    expect(service.hasTemplates, isTrue);
    expect(service.isInitialized, isFalse);

    final result = await service.init('acme');
    expect(result.profileId, 'acme');
    expect(result.created, isNotEmpty);
    expect(
      File('${root.path}/.vet45/profiles/acme/local.env').existsSync(),
      isTrue,
    );
    expect(
      File('${root.path}/.vet45/profiles/acme/local.env.example').existsSync(),
      isTrue,
    );
    expect(
      File('${root.path}/.vet45/profiles/acme/auth.env.example').existsSync(),
      isTrue,
    );
    expect(
      File('${root.path}/.vet45/profiles/acme/auth.env').existsSync(),
      isFalse,
    );
    expect(
      File('${root.path}/.vet45/deploy/deploy.env').existsSync(),
      isTrue,
    );

    final state = readActiveState(
      root,
      defaultEnvironmentId: 'local',
    );
    expect(state.profileId, 'acme');
    expect(state.environmentId, 'local');

    final manifest = EnvManifest.load(root);
    expect(manifest.profiles.profiles.keys, contains('acme'));
    expect(manifest.profiles.profiles.containsKey('deploy'), isFalse);
  });

  test('init skips filled secrets', () async {
    final service = ConfigInitService(repoRoot: root);
    await service.init('acme');
    writeDotEnv(
      File('${root.path}/.vet45/profiles/acme/local.env'),
      {'SUPABASE_URL': 'https://filled.supabase.co'},
    );

    final result = await service.init('acme', force: true);
    expect(
      File('${root.path}/.vet45/profiles/acme/local.env').readAsStringSync(),
      contains('filled.supabase.co'),
    );
    expect(result.skipped, contains('.vet45/profiles/acme/local.env'));
  });

  test('init fails without workspace manifest', () async {
    File('${root.path}/vet45.workspace.json').deleteSync();
    final service = ConfigInitService(repoRoot: root);
    expect(
      () => service.init('acme'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('vet45.workspace.json'),
        ),
      ),
    );
  });

  test('init rejects reserved deploy id', () async {
    final service = ConfigInitService(repoRoot: root);
    expect(
      () => service.init('deploy'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('reserved'),
        ),
      ),
    );
  });
}
