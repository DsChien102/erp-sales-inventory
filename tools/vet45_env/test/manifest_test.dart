import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/doctor_service.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/secrets_loader.dart';
import 'package:vet45_env/sync_service.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;
  late EnvManifest manifest;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_env_test_');
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
  }
}
'''),
    );
    manifest = EnvManifest.load(root);
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('load manifest validates default environment and targets', () {
    expect(manifest.defaultEnvironmentId, 'local');
    expect(manifest.environments.containsKey('local'), isTrue);
    expect(manifest.targets.keys, containsAll(['erp', 'worker', 'deploy']));
    expect(manifest.getEnvironment('local').erp?.flavor, 'development');
    expect(manifest.deploySecretsFile.path, endsWith('config/secrets/deploy.env'));
    expect(manifest.profiles.defaultProfileId, 'default');
  });

  test('default environment id falls back to development', () {
    File('${root.path}/config/environments.json').writeAsStringSync(
      manifestWithEnv(
        '''
{
  "development": {
    "description": "test dev",
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
  }
}
''',
        defaultId: 'development',
      ),
    );
    final m = EnvManifest.load(root);
    expect(m.defaultEnvironmentId, 'development');
    expect(m.deploySecretsFile.path, endsWith('config/secrets/deploy.env'));
  });

  test('rejects unknown target id in per-env bindings', () {
    File('${root.path}/config/environments.json').writeAsStringSync(
      manifestWithEnv('''
{
  "local": {
    "description": "bad",
    "supabaseSource": "secrets",
    "targets": {
      "unknown_app": {
        "envFile": "apps/unknown/.env"
      }
    }
  }
}
'''),
    );
    expect(
      () => EnvManifest.load(root),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('unknown target'),
        ),
      ),
    );
  });

  test('sync writes erp and worker env from secrets', () async {
    writeDotEnv(
      File('${root.path}/config/secrets/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon-test',
        'SUPABASE_SERVICE_ROLE_KEY': 'service-test',
        'WORKER_TICK_SECRET': 'tick-test',
      },
    );

    final result = await SyncService(manifest: manifest).sync(
      testContext(manifest, 'local'),
    );

    expect(result.ok, isTrue);
    expect(result.erpEnvFile!.existsSync(), isTrue);
    expect(result.workerEnvFile!.existsSync(), isTrue);

    final erp = loadDotEnv(result.erpEnvFile!);
    expect(erp['SUPABASE_CONNECTION_URL'], 'http://127.0.0.1:54321');
    expect(erp['APP_ENV'], 'development');

    final worker = loadDotEnv(result.workerEnvFile!);
    expect(worker['SUPABASE_URL'], 'http://127.0.0.1:54321');
    expect(worker['WORKER_TICK_SECRET'], 'tick-test');
    expect(worker['WORKER_LOG_LEVEL'], 'WARNING');
  });

  test('sync does not copy APP_STORE_CONNECT keys into erp env', () async {
    Directory('${root.path}/apps/erp').createSync(recursive: true);
    writeDotEnv(
      File('${root.path}/config/secrets/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon-test',
        'SUPABASE_SERVICE_ROLE_KEY': 'service-test',
        'WORKER_TICK_SECRET': 'tick-test',
        'APP_STORE_CONNECT_ISSUER_ID': 'issuer-from-secrets',
        'APP_STORE_CONNECT_KEY_IDENTIFIER': 'key-from-secrets',
      },
    );
    writeDotEnv(
      File('${root.path}/apps/erp/.env'),
      {
        'APP_STORE_CONNECT_ISSUER_ID': 'issuer-legacy-erp',
        'APP_STORE_CONNECT_KEY_IDENTIFIER': 'key-legacy-erp',
      },
    );

    final result = await SyncService(manifest: manifest).sync(
      testContext(manifest, 'local'),
    );
    final erp = loadDotEnv(result.erpEnvFile!);

    expect(erp.containsKey('APP_STORE_CONNECT_ISSUER_ID'), isFalse);
    expect(erp.containsKey('APP_STORE_CONNECT_KEY_IDENTIFIER'), isFalse);
  });

  test('full sync partial success when worker keys missing', () async {
    writeDotEnv(
      File('${root.path}/config/secrets/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon-test',
      },
    );

    final result = await SyncService(manifest: manifest).sync(
      testContext(manifest, 'local'),
    );

    expect(result.ok, isFalse);
    expect(result.failures.keys, contains('worker'));
    expect(result.writtenFiles.keys, contains('erp'));
    expect(result.erpEnvFile!.existsSync(), isTrue);
    expect(result.workerEnvFile, isNull);
    expect(
      File('${root.path}/apps/messaging_worker/.env').existsSync(),
      isFalse,
    );

    final erp = loadDotEnv(result.erpEnvFile!);
    expect(erp['SUPABASE_CONNECTION_URL'], 'http://127.0.0.1:54321');
  });

  test('sync --target erp succeeds without worker keys', () async {
    writeDotEnv(
      File('${root.path}/config/secrets/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon-test',
      },
    );

    final result = await SyncService(manifest: manifest).sync(
      testContext(manifest, 'local'),
      targetId: 'erp',
    );

    expect(result.ok, isTrue);
    expect(result.writtenFiles.keys, ['erp']);
    expect(result.failures, isEmpty);
  });

  test('autoGenerate WORKER_TICK_SECRET only when syncing worker', () async {
    writeDotEnv(
      File('${root.path}/config/secrets/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon-test',
        'SUPABASE_SERVICE_ROLE_KEY': 'service-test',
      },
    );

    final erpOnly = await SyncService(manifest: manifest).sync(
      testContext(manifest, 'local'),
      targetId: 'erp',
    );
    expect(erpOnly.ok, isTrue);
    final secretsAfterErp = loadDotEnv(
      File('${root.path}/config/secrets/local.env'),
    );
    expect(secretsAfterErp.containsKey('WORKER_TICK_SECRET'), isFalse);

    final workerOnly = await SyncService(manifest: manifest).sync(
      testContext(manifest, 'local'),
      targetId: 'worker',
    );
    expect(workerOnly.ok, isTrue);
    final secretsAfterWorker = loadDotEnv(
      File('${root.path}/config/secrets/local.env'),
    );
    expect(secretsAfterWorker['WORKER_TICK_SECRET'], isNotEmpty);
    final worker = loadDotEnv(workerOnly.workerEnvFile!);
    expect(worker['WORKER_TICK_SECRET'], secretsAfterWorker['WORKER_TICK_SECRET']);
  });

  test('doctor --target erp ignores missing deploy secrets', () async {
    writeDotEnv(
      File('${root.path}/config/secrets/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon-test',
      },
    );
    await SyncService(manifest: manifest).sync(
      testContext(manifest, 'local'),
      targetId: 'erp',
    );

    final report = await DoctorService(
      manifest: manifest,
      skipNetwork: true,
    ).run(testContext(manifest, 'local'), targetId: 'erp');

    expect(report.ok, isTrue);
    expect(
      report.checks.any((c) => c.name.startsWith('deploy')),
      isFalse,
    );
  });

  test('doctor deploy fails when deploy secrets missing', () async {
    final report = await DoctorService(
      manifest: manifest,
      skipNetwork: true,
    ).run(testContext(manifest, 'local'), targetId: 'deploy');

    expect(report.ok, isFalse);
    expect(
      report.checks.any((c) => c.name == 'deploy secrets file' && !c.passed),
      isTrue,
    );
  });

  test('doctor deploy passes when deploy secrets present', () async {
    writeDotEnv(
      File('${root.path}/config/secrets/deploy.env'),
      {
        'APP_STORE_CONNECT_ISSUER_ID': 'issuer',
        'APP_STORE_CONNECT_KEY_IDENTIFIER': 'key-id',
      },
    );

    final report = await DoctorService(
      manifest: manifest,
      skipNetwork: true,
    ).run(testContext(manifest, 'local'), targetId: 'deploy');

    expect(report.ok, isTrue);
  });

  test('write and read active environment', () {
    writeActive(root, 'local');
    expect(readActive(root), 'local');
  });

  test('write and read active state with profile', () {
    writeActiveState(
      root,
      ActiveState(profileId: 'default', environmentId: 'local'),
    );
    final state = readActiveState(
      root,
      defaultProfileId: 'default',
      defaultEnvironmentId: 'development',
    );
    expect(state.profileId, 'default');
    expect(state.environmentId, 'local');
    expect(readActive(root), 'local');
  });
}
