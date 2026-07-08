import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/doctor_service.dart';
import 'package:vet45_env/link_service.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/process_runner.dart';
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
    Directory('${root.path}/config/secrets').createSync(recursive: true);
    Directory('${root.path}/apps/erp').createSync(recursive: true);
    Directory('${root.path}/apps/messaging_worker').createSync(recursive: true);
    File('${root.path}/config/environments.json').writeAsStringSync(
      manifestWithEnv('''
{
  "local": {
    "description": "test local",
    "secretsFile": "config/secrets/local.env",
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
      File('${root.path}/config/secrets/local.env'),
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
      File('${root.path}/config/secrets/local.env'),
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
      File('${root.path}/config/secrets/local.env'),
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

  test('loadDotEnv strips CRLF from values', () {
    final file = File('${root.path}/config/secrets/crlf.env');
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
