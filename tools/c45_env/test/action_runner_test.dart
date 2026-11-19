import 'dart:io';

import 'package:test/test.dart';
import 'package:c45_env/action_runner.dart';
import 'package:c45_env/action_spec.dart';
import 'package:c45_env/doctor_service.dart';
import 'package:c45_env/manifest.dart';
import 'package:c45_env/process_runner.dart';
import 'package:c45_env/secrets_loader.dart';
import 'package:c45_env/sync_service.dart';

import 'test_manifest_fixture.dart';

void main() {
  group('ActionTemplate', () {
    test('expands known variables and empty for missing', () {
      final template = ActionTemplate({
        'flavor': 'staging',
        'envBasename': '.env.staging',
      });
      expect(
        template.expand(
          'run --flavor {{flavor}} --dart-define-from-file={{envBasename}}',
        ),
        'run --flavor staging --dart-define-from-file=.env.staging',
      );
      expect(template.expand('{{missing}}'), '');
    });
  });

  group('ActionRunner', () {
    late Directory root;
    late EnvManifest manifest;
    late _RecordingProcessRunner process;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('c45_action_test_');
      writeTestWorkspace(root);
      Directory('${root.path}/apps/erp').createSync(recursive: true);
      Directory('${root.path}/apps/worker').createSync(recursive: true);
      manifest = EnvManifest.load(root);
      process = _RecordingProcessRunner();
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    ActionRunner runner() => ActionRunner(
          manifest: manifest,
          doctorService: DoctorService(manifest: manifest, skipNetwork: true),
          processRunner: process,
        );

    Future<void> syncLocal() async {
      writeDotEnv(
        File('${root.path}/.c45/profiles/default/local.env'),
        {
          'SUPABASE_URL': 'http://127.0.0.1:54321',
          'SUPABASE_ANON_KEY': 'anon-test',
          'SUPABASE_SERVICE_ROLE_KEY': 'service-test',
          'WORKER_TICK_SECRET': 'tick-test',
        },
      );
      writeActive(root, 'local');
      final result = await SyncService(manifest: manifest).sync(
        manifest.context(environmentId: 'local'),
      );
      expect(result.ok, isTrue);
    }

    test('runs erp debug with template expansion', () async {
      await syncLocal();

      final code = await runner().run(
        ctx: manifest.context(environmentId: 'local'),
        targetId: 'erp',
        actionId: 'debug',
      );

      expect(code, 0);
      expect(process.invocations.single.executable, 'flutter');
      expect(process.invocations.single.arguments, contains('development'));
      expect(
        process.invocations.single.arguments,
        contains('--dart-define-from-file=.env'),
      );
    });

    test('worker serve passes dotenv into environment', () async {
      writeDotEnv(
        File('${root.path}/.c45/profiles/default/local.env'),
        {
          'SUPABASE_URL': 'http://example.supabase.co',
          'SUPABASE_SERVICE_ROLE_KEY': 'service-test',
          'WORKER_TICK_SECRET': 'tick-test',
        },
      );
      writeActive(root, 'local');
      await SyncService(manifest: manifest).sync(
        manifest.context(environmentId: 'local'),
        targetId: 'worker',
      );

      final code = await runner().run(
        ctx: manifest.context(environmentId: 'local'),
        targetId: 'worker',
        actionId: 'serve',
      );

      expect(code, 0);
      expect(process.invocations.single.executable, 'dart');
      expect(
        process.invocations.single.environment?['SUPABASE_URL'],
        'http://example.supabase.co',
      );
    });

    test('debug:ios returns 64 on non-macOS', () async {
      if (Platform.isMacOS) {
        return;
      }
      await syncLocal();

      final code = await runner().run(
        ctx: manifest.context(environmentId: 'local'),
        targetId: 'erp',
        actionId: 'debug:ios',
      );

      expect(code, 64);
      expect(process.invocations, isEmpty);
    });

    test('unknown action returns 64', () async {
      final code = await runner().run(
        ctx: manifest.context(environmentId: 'local'),
        targetId: 'erp',
        actionId: 'missing',
      );
      expect(code, 64);
    });

    test('requireRailwayEnvironment fails for development', () async {
      await syncLocal();

      final code = await runner().run(
        ctx: manifest.context(environmentId: 'local'),
        targetId: 'worker',
        actionId: 'deploy',
      );

      expect(code, 1);
      expect(process.invocations, isEmpty);
    });

    test('resolveLaunch expands erp debug without running process', () async {
      await syncLocal();

      final plan = await runner().resolveLaunch(
        ctx: manifest.context(environmentId: 'local'),
        targetId: 'erp',
        actionId: 'debug',
      );

      expect(plan.label, 'erp/debug');
      expect(plan.command, 'flutter');
      expect(plan.args, contains('development'));
      expect(plan.args, contains('--dart-define-from-file=.env'));
      expect(plan.workingDirectory, endsWith('apps/erp'));
      expect(process.invocations, isEmpty);
    });

    test('worker docker local rewrites Supabase to host.docker.internal',
        () async {
      await syncLocal();

      final plan = await runner().resolveLaunch(
        ctx: manifest.context(environmentId: 'local'),
        targetId: 'worker',
        actionId: 'docker',
      );

      expect(plan.label, 'worker/docker');
      expect(plan.command, endsWith('worker_docker.sh'));
      expect(
        plan.environment['WORKER_SUPABASE_URL'],
        'http://host.docker.internal:54321',
      );
      expect(plan.environment['WORKER_IMAGE_TAG'], 'local');
      expect(
        plan.environment['WORKER_ENV_FILE'],
        endsWith('apps/worker/.env'),
      );
      expect(process.invocations, isEmpty);
    });

    test('worker docker remote keeps generated SUPABASE_URL', () async {
      final remoteRoot = await Directory.systemTemp.createTemp(
        'c45_docker_dev_',
      );
      addTearDown(() {
        if (remoteRoot.existsSync()) {
          remoteRoot.deleteSync(recursive: true);
        }
      });
      writeTestWorkspace(
        remoteRoot,
        defaultEnvironment: 'development',
        environmentIds: const ['development'],
      );
      writeDotEnv(
        File('${remoteRoot.path}/.c45/profiles/default/development.env'),
        {
          'SUPABASE_URL': 'https://example.supabase.co',
          'SUPABASE_ANON_KEY': 'anon-test',
          'SUPABASE_SERVICE_ROLE_KEY': 'service-test',
          'WORKER_TICK_SECRET': 'tick-test',
        },
      );
      writeActive(remoteRoot, 'development');
      final remoteManifest = EnvManifest.load(remoteRoot);
      final sync = await SyncService(manifest: remoteManifest).sync(
        remoteManifest.context(environmentId: 'development'),
        targetId: 'worker',
      );
      expect(sync.ok, isTrue);

      final plan = await ActionRunner(
        manifest: remoteManifest,
        doctorService: DoctorService(
          manifest: remoteManifest,
          skipNetwork: true,
        ),
        processRunner: process,
      ).resolveLaunch(
        ctx: remoteManifest.context(environmentId: 'development'),
        targetId: 'worker',
        actionId: 'docker',
      );

      expect(plan.environment.containsKey('WORKER_SUPABASE_URL'), isFalse);
      expect(plan.environment['WORKER_IMAGE_TAG'], 'development');
      expect(
        plan.environment['WORKER_ENV_FILE'],
        endsWith('apps/worker/.env'),
      );
    });

    test('resolveLaunch rejects debug:ios on non-macOS', () async {
      if (Platform.isMacOS) {
        return;
      }
      await syncLocal();

      expect(
        () => runner().resolveLaunch(
          ctx: manifest.context(environmentId: 'local'),
          targetId: 'erp',
          actionId: 'debug:ios',
        ),
        throwsA(
          isA<ActionLaunchException>().having((e) => e.exitCode, 'code', 64),
        ),
      );
    });
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
