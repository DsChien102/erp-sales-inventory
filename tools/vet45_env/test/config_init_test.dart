import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/config_init_service.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/secrets_loader.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_config_init_');
    File('${root.path}/pubspec.yaml').writeAsStringSync('name: vet45\n');
    writeTestWorkspace(root);
    // Committed examples under config/default + config/deploy
    Directory('${root.path}/config/default').createSync(recursive: true);
    Directory('${root.path}/config/deploy').createSync(recursive: true);
    File('${root.path}/config/default/development.env.example').writeAsStringSync(
      'SUPABASE_URL=\nSUPABASE_ANON_KEY=\n',
    );
    File('${root.path}/config/default/auth.env.example').writeAsStringSync(
      'SUPABASE_ACCESS_TOKEN=\n',
    );
    File('${root.path}/config/deploy/deploy.env.example').writeAsStringSync(
      'APP_STORE_CONNECT_ISSUER_ID=\nAPP_STORE_CONNECT_KEY_IDENTIFIER=\n',
    );
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('init copies examples to env files when missing', () async {
    final service = ConfigInitService(repoRoot: root);
    expect(service.hasWorkspace, isTrue);
    expect(service.isInitialized, isTrue);

    final result = await service.init();
    expect(result.created, isNotEmpty);
    expect(
      File('${root.path}/config/default/development.env').existsSync(),
      isTrue,
    );
    expect(
      File('${root.path}/config/deploy/deploy.env').existsSync(),
      isTrue,
    );

    final manifest = EnvManifest.load(root);
    expect(manifest.defaultEnvironmentId, 'local');
  });

  test('init skips filled secrets', () async {
    final service = ConfigInitService(repoRoot: root);
    writeDotEnv(
      File('${root.path}/config/default/development.env'),
      {'SUPABASE_URL': 'https://filled.supabase.co'},
    );

    final result = await service.init(force: true);
    expect(
      File('${root.path}/config/default/development.env').readAsStringSync(),
      contains('filled.supabase.co'),
    );
    expect(result.skipped, contains('config/default/development.env'));
  });

  test('init fails without workspace manifest', () async {
    File('${root.path}/vet45.workspace.json').deleteSync();
    final service = ConfigInitService(repoRoot: root);
    expect(
      () => service.init(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('vet45.workspace.json'),
        ),
      ),
    );
  });
}
