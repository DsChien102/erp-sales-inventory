import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/doctor_service.dart';
import 'package:vet45_env/link_service.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/process_runner.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/run_service.dart';
import 'package:vet45_env/secrets_loader.dart';
import 'package:vet45_env/sync_service.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;
  late EnvManifest manifest;
  late _RecordingProcessRunner process;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_run_test_');
    writeTestWorkspace(root);
    Directory('${root.path}/apps/erp').createSync(recursive: true);
    Directory('${root.path}/apps/messaging_worker').createSync(recursive: true);
    manifest = EnvManifest.load(root);
    process = _RecordingProcessRunner();
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  RunService service() {
    return RunService(
      manifest: manifest,
      syncService: SyncService(manifest: manifest),
      linkService: SupabaseLinkService(manifest: manifest),
      doctorService: DoctorService(manifest: manifest, skipNetwork: true),
      processRunner: process,
    );
  }

  test('run erp debug invokes flutter with flavor and env file', () async {
    writeDotEnv(
      File('${root.path}/config/default/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon-test',
      },
    );
    writeActive(root, 'local');

    final code = await service().run('erp', 'debug');

    expect(code, 0);
    expect(process.invocations, hasLength(1));
    expect(process.invocations.first.executable, 'flutter');
    expect(process.invocations.first.arguments, contains('development'));
    expect(process.invocations.first.arguments, contains('--dart-define-from-file=.env'));
    expect(
      process.invocations.first.workingDirectory!.replaceAll('\\', '/'),
      endsWith('apps/erp'),
    );
  });

  test('run worker serve loads dotenv into process environment', () async {
    writeDotEnv(
      File('${root.path}/config/default/local.env'),
      {
        'SUPABASE_URL': 'http://example.supabase.co',
        'SUPABASE_SERVICE_ROLE_KEY': 'service-test',
        'WORKER_TICK_SECRET': 'tick-test',
      },
    );
    writeActive(root, 'local');

    final code = await service().run('worker', 'serve');

    expect(code, 0);
    expect(process.invocations, hasLength(1));
    expect(process.invocations.first.executable, 'dart');
    expect(process.invocations.first.arguments, contains('--serve'));
    expect(
      process.invocations.first.environment?['SUPABASE_URL'],
      'http://example.supabase.co',
    );
    expect(
      process.invocations.first.environment?['WORKER_TICK_SECRET'],
      'tick-test',
    );
  });

  test('debug:ios returns 64 on non-macOS', () async {
    if (Platform.isMacOS) {
      return;
    }
    writeDotEnv(
      File('${root.path}/config/default/local.env'),
      {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'anon-test',
      },
    );
    writeActive(root, 'local');

    final code = await service().run('erp', 'debug:ios');

    expect(code, 64);
    expect(process.invocations, isEmpty);
  });

  test('switchWorkspace changes profile and writes erp env', () async {
    Directory('${root.path}/config/acme').createSync(recursive: true);
    writeTestWorkspace(
      root,
      profiles: {
        'default': {
          'description': 'Default',
          'secretsRoot': 'config/default',
        },
        'acme': {
          'description': 'Acme',
          'secretsRoot': 'config/acme',
        },
      },
    );
    manifest = EnvManifest.load(root);

    writeDotEnv(
      File('${root.path}/config/default/local.env'),
      {
        'SUPABASE_URL': 'http://default.example',
        'SUPABASE_ANON_KEY': 'default-anon',
      },
    );
    writeDotEnv(
      File('${root.path}/config/acme/local.env'),
      {
        'SUPABASE_URL': 'http://acme.example',
        'SUPABASE_ANON_KEY': 'acme-anon',
        'SUPABASE_SERVICE_ROLE_KEY': 'acme-service',
        'WORKER_TICK_SECRET': 'acme-tick',
      },
    );
    writeActiveState(
      root,
      ActiveState(profileId: 'default', environmentId: 'local'),
    );

    await service().switchWorkspace(profileId: 'acme');

    final state = readActiveState(
      root,
      defaultProfileId: manifest.profiles.defaultProfileId,
      defaultEnvironmentId: manifest.defaultEnvironmentId,
    );
    expect(state.profileId, 'acme');
    expect(state.environmentId, 'local');

    final erpEnv = File('${root.path}/apps/erp/.env');
    expect(erpEnv.existsSync(), isTrue);
    final values = loadDotEnv(erpEnv);
    expect(values['SUPABASE_CONNECTION_URL'], 'http://acme.example');
    expect(values['SUPABASE_ANON_KEY'], 'acme-anon');
  });

  test('switchWorkspace changes profile and environment together', () async {
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
    manifest = EnvManifest.load(root);

    writeDotEnv(
      File('${root.path}/config/default/staging.env'),
      {
        'SUPABASE_URL': 'http://staging.example',
        'SUPABASE_ANON_KEY': 'staging-anon',
        'SUPABASE_SERVICE_ROLE_KEY': 'staging-service',
        'WORKER_TICK_SECRET': 'staging-tick',
      },
    );
    writeActiveState(
      root,
      ActiveState(profileId: 'default', environmentId: 'local'),
    );

    await service().switchWorkspace(environmentId: 'staging');

    final state = readActiveState(
      root,
      defaultProfileId: manifest.profiles.defaultProfileId,
      defaultEnvironmentId: manifest.defaultEnvironmentId,
    );
    expect(state.environmentId, 'staging');

    final erpEnv = File('${root.path}/apps/erp/.env.staging');
    expect(erpEnv.existsSync(), isTrue);
    expect(loadDotEnv(erpEnv)['APP_ENV'], 'staging');
  });

  test('loadDotEnv strips CRLF from values', () {
    final file = File('${root.path}/config/default/crlf.env');
    file.writeAsStringSync('KEY=value\r\nOTHER=ok\r\n');
    final values = loadDotEnv(file);
    expect(values['KEY'], 'value');
    expect(values['OTHER'], 'ok');
  });
}

class _RecordingProcessRunner implements ProcessRunner {
  final invocations = <_Invocation>[];

  @override
  Future<int> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool inheritStdio = true,
  }) async {
    invocations.add(
      _Invocation(
        executable: executable,
        arguments: List.unmodifiable(arguments),
        workingDirectory: workingDirectory,
        environment: environment == null ? null : Map.unmodifiable(environment),
      ),
    );
    return 0;
  }
}

class _Invocation {
  _Invocation({
    required this.executable,
    required this.arguments,
    this.workingDirectory,
    this.environment,
  });

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  final Map<String, String>? environment;
}
