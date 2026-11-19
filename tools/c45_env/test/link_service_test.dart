import 'dart:io';

import 'package:test/test.dart';
import 'package:c45_env/link_service.dart';
import 'package:c45_env/manifest.dart';
import 'package:c45_env/project_ref.dart';
import 'package:c45_env/secrets_loader.dart';
import 'package:c45_env/supabase_cli.dart';

import 'test_manifest_fixture.dart';

void main() {
  group('ProjectRefResolver', () {
    test('parses hosted supabase URL', () {
      expect(
        ProjectRefResolver.parseFromUrl('https://abc123xyz.supabase.co'),
        'abc123xyz',
      );
      expect(ProjectRefResolver.parseFromUrl('http://127.0.0.1:54321'), isNull);
    });

    test('resolves from secrets URL', () async {
      final root = await Directory.systemTemp.createTemp('c45_ref_test_');
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      writeTestWorkspace(
        root,
        defaultEnvironment: 'staging',
        environmentIds: ['staging'],
        erpEnvOverrides: {
          'staging': {
            'envFile': '.env.staging',
            'flavor': 'staging',
            'appEnv': 'staging',
          },
        },
        workerEnvOverrides: {
          'staging': {'envFile': '.env.staging'},
        },
      );
      final secretsFile = File('${root.path}/.c45/profiles/default/staging.env');
      writeDotEnv(
        secretsFile,
        {'SUPABASE_URL': 'https://myprojref.supabase.co'},
      );
      final manifest = EnvManifest.load(root);
      final env = manifest.getEnvironment('staging');
      expect(ProjectRefResolver.resolve(env, secretsFile), 'myprojref');
    });

    test('manifest supabaseProjectRef takes priority', () async {
      final root = await Directory.systemTemp.createTemp('c45_ref_test_');
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      writeTestWorkspace(
        root,
        defaultEnvironment: 'staging',
        environmentIds: ['staging'],
        environmentMeta: {
          'staging': {'supabaseProjectRef': 'explicitref'},
        },
        erpEnvOverrides: {
          'staging': {
            'envFile': '.env.staging',
            'flavor': 'staging',
            'appEnv': 'staging',
          },
        },
        workerEnvOverrides: {
          'staging': {'envFile': '.env.staging'},
        },
      );
      final secretsFile = File('${root.path}/.c45/profiles/default/staging.env');
      writeDotEnv(
        secretsFile,
        {'SUPABASE_URL': 'https://otherref.supabase.co'},
      );
      final manifest = EnvManifest.load(root);
      final env = manifest.getEnvironment('staging');
      expect(ProjectRefResolver.resolve(env, secretsFile), 'explicitref');
    });
  });

  group('SupabaseLinkService', () {
    late Directory root;
    late EnvManifest manifest;
    late _RecordingSupabaseCli cli;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('c45_link_test_');
      Directory('${root.path}/supabase/.temp').createSync(recursive: true);
      writeTestWorkspace(
        root,
        defaultEnvironment: 'staging',
        environmentIds: ['staging', 'local'],
        environmentMeta: {
          'local': {
            'supabaseSource': 'supabase_cli',
            'syncSupabaseLink': false,
          },
        },
        erpEnvOverrides: {
          'staging': {
            'envFile': '.env.staging',
            'flavor': 'staging',
            'appEnv': 'staging',
          },
          'local': {
            'envFile': '.env',
            'flavor': 'development',
            'appEnv': 'development',
          },
        },
        workerEnvOverrides: {
          'staging': {'envFile': '.env.staging'},
          'local': {'envFile': '.env'},
        },
      );
      writeDotEnv(
        File('${root.path}/.c45/profiles/default/staging.env'),
        {
          'SUPABASE_URL': 'https://targetref.supabase.co',
          'SUPABASE_ANON_KEY': 'anon',
          'SUPABASE_SERVICE_ROLE_KEY': 'service',
        },
      );
      manifest = EnvManifest.load(root);
      cli = _RecordingSupabaseCli();
    });

    tearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    test('links when current ref differs', () async {
      File('${root.path}/supabase/.temp/project-ref').writeAsStringSync('oldref');

      final result = await SupabaseLinkService(
        manifest: manifest,
        supabaseCli: cli,
      ).ensureLinked(testContext(manifest, 'staging'));

      expect(result.action, LinkAction.linked);
      expect(cli.linkedRef, 'targetref');
    });

    test('skips when already linked', () async {
      File('${root.path}/supabase/.temp/project-ref')
          .writeAsStringSync('targetref');

      final result = await SupabaseLinkService(
        manifest: manifest,
        supabaseCli: cli,
      ).ensureLinked(testContext(manifest, 'staging'));

      expect(result.action, LinkAction.alreadyLinked);
      expect(cli.linkCalls, 0);
    });

    test('skips for local environment', () async {
      final result = await SupabaseLinkService(
        manifest: manifest,
        supabaseCli: cli,
      ).ensureLinked(testContext(manifest, 'local'));

      expect(result.action, LinkAction.skipped);
      expect(cli.linkCalls, 0);
    });
  });

  group('SupabaseCli.readLinkedProjectRef', () {
    test('reads project-ref file', () async {
      final root = await Directory.systemTemp.createTemp('c45_cli_test_');
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      Directory('${root.path}/supabase/.temp').createSync(recursive: true);
      File('${root.path}/supabase/.temp/project-ref').writeAsStringSync('abc123\n');
      expect(SupabaseCli.readLinkedProjectRef(root), 'abc123');
    });
  });
}

class _RecordingSupabaseCli extends SupabaseCli {
  _RecordingSupabaseCli() : super(workdir: null);

  int linkCalls = 0;
  String? linkedRef;

  @override
  Future<void> linkProject({
    required String projectRef,
    String? dbPassword,
  }) async {
    linkCalls++;
    linkedRef = projectRef;
  }
}
