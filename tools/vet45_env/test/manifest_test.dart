import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/secrets_loader.dart';
import 'package:vet45_env/sync_service.dart';

void main() {
  late Directory root;
  late EnvManifest manifest;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_env_test_');
    final configDir = Directory('${root.path}/config/secrets');
    configDir.createSync(recursive: true);
    File('${root.path}/config/environments.json').writeAsStringSync('''
{
  "default": "local",
  "environments": {
    "local": {
      "description": "test local",
      "secretsFile": "config/secrets/local.env",
      "supabaseSource": "secrets",
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
''');
    manifest = EnvManifest.load(root);
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('load manifest validates default environment', () {
    expect(manifest.defaultEnvironmentId, 'local');
    expect(manifest.environments.containsKey('local'), isTrue);
    expect(manifest.getEnvironment('local').erp.flavor, 'development');
  });

  test('default environment id falls back to development', () {
    File('${root.path}/config/environments.json').writeAsStringSync('''
{
  "environments": {
    "development": {
      "description": "test dev",
      "secretsFile": "config/secrets/development.env",
      "supabaseSource": "secrets",
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
''');
    final m = EnvManifest.load(root);
    expect(m.defaultEnvironmentId, 'development');
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

    final result = await SyncService(manifest: manifest).sync('local');

    expect(result.erpEnvFile.existsSync(), isTrue);
    expect(result.workerEnvFile.existsSync(), isTrue);

    final erp = loadDotEnv(result.erpEnvFile);
    expect(erp['SUPABASE_CONNECTION_URL'], 'http://127.0.0.1:54321');
    expect(erp['APP_ENV'], 'development');

    final worker = loadDotEnv(result.workerEnvFile);
    expect(worker['SUPABASE_URL'], 'http://127.0.0.1:54321');
    expect(worker['WORKER_TICK_SECRET'], 'tick-test');
  });

  test('write and read active environment', () {
    writeActive(root, 'local');
    expect(readActive(root), 'local');
  });
}
