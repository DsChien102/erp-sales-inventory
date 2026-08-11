import 'package:test/test.dart';
import 'package:vet45_env/platform_admin_command_args.dart';
import 'package:vet45_env/platform_admin_service.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/supabase_admin_client.dart';
import 'package:vet45_env/manifest.dart';

import 'test_manifest_fixture.dart';
import 'dart:io';

final class _RecordingHttp implements SupabaseAdminHttp {
  _RecordingHttp(this._handler);

  final Future<SupabaseAdminHttpResponse> Function({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  })
  _handler;

  final calls = <({String method, String path})>[];

  @override
  Future<SupabaseAdminHttpResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    calls.add((method: method, path: uri.path));
    return _handler(
      method: method,
      uri: uri,
      headers: headers,
      body: body,
    );
  }

  @override
  void close() {}
}

void main() {
  group('PlatformAdminCommandArgs', () {
    test('parses create flags', () {
      final parsed = PlatformAdminCommandArgs.parse([
        'create',
        '--email',
        'a@b.c',
        '--password',
        'secret',
        '--env',
        'local',
        '--profile',
        'acme',
        '--yes',
      ]);
      expect(parsed.subcommand, 'create');
      expect(parsed.email, 'a@b.c');
      expect(parsed.password, 'secret');
      expect(parsed.environmentId, 'local');
      expect(parsed.profileId, 'acme');
      expect(parsed.yes, isTrue);
    });

    test('rejects unknown subcommand', () {
      expect(
        () => PlatformAdminCommandArgs.parse(['delete']),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('PlatformAdminService', () {
    late Directory root;
    late EnvManifest manifest;
    late WorkspaceContext ctx;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('vet45_admin_');
      writeTestWorkspace(
        root,
        environmentIds: ['local', 'staging'],
        profileIds: ['default'],
      );
      manifest = EnvManifest.load(root);
      final profileDir = Directory('${root.path}/.vet45/profiles/default');
      profileDir.createSync(recursive: true);
      File('${profileDir.path}/local.env').writeAsStringSync('''
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_SERVICE_ROLE_KEY=service-role-test
''');
      File('${root.path}/.vet45/state.json').writeAsStringSync(
        '{"profile":"default","environment":"local"}',
      );
      ctx = manifest.context(profileId: 'default', environmentId: 'local');
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('create new user then grant', () async {
      final http = _RecordingHttp(({
        required method,
        required uri,
        required headers,
        body,
      }) async {
        if (method == 'POST' && uri.path.endsWith('/auth/v1/admin/users')) {
          return const SupabaseAdminHttpResponse(
            statusCode: 200,
            body: '{"id":"user-1","email":"admin@local.test"}',
          );
        }
        if (method == 'POST' && uri.path.endsWith('/rest/v1/platform_admins')) {
          return const SupabaseAdminHttpResponse(
            statusCode: 201,
            body: '[{"user_id":"user-1"}]',
          );
        }
        fail('Unexpected ${method} ${uri.path}');
      });

      final service = PlatformAdminService(
        manifest: manifest,
        http: http,
        loadCanonical: (_) async => {
          'SUPABASE_URL': 'http://127.0.0.1:54321',
          'SUPABASE_SERVICE_ROLE_KEY': 'service-role-test',
        },
      );

      final result = await service.create(
        ctx: ctx,
        email: 'Admin@Local.Test',
        password: 'fixed-pass',
      );

      expect(result.createdUser, isTrue);
      expect(result.userId, 'user-1');
      expect(result.email, 'admin@local.test');
      expect(result.granted, isTrue);
      expect(result.generatedPassword, isNull);
      expect(http.calls.map((c) => c.method), ['POST', 'POST']);
    });

    test('create existing email grants without recreating password', () async {
      var createCalls = 0;
      final http = _RecordingHttp(({
        required method,
        required uri,
        required headers,
        body,
      }) async {
        if (method == 'POST' && uri.path.endsWith('/auth/v1/admin/users')) {
          createCalls++;
          return const SupabaseAdminHttpResponse(
            statusCode: 422,
            body: '{"msg":"User already registered","error_code":"email_exists"}',
          );
        }
        if (method == 'GET' && uri.path.endsWith('/auth/v1/admin/users')) {
          return const SupabaseAdminHttpResponse(
            statusCode: 200,
            body:
                '{"users":[{"id":"user-existing","email":"admin@local.test"}]}',
          );
        }
        if (method == 'POST' && uri.path.endsWith('/rest/v1/platform_admins')) {
          return const SupabaseAdminHttpResponse(
            statusCode: 200,
            body: '[{"user_id":"user-existing"}]',
          );
        }
        fail('Unexpected ${method} ${uri.path}');
      });

      final service = PlatformAdminService(
        manifest: manifest,
        http: http,
        loadCanonical: (_) async => {
          'SUPABASE_URL': 'http://127.0.0.1:54321',
          'SUPABASE_SERVICE_ROLE_KEY': 'service-role-test',
        },
      );

      final result = await service.create(
        ctx: ctx,
        email: 'admin@local.test',
        password: 'ignored',
      );

      expect(createCalls, 1);
      expect(result.createdUser, isFalse);
      expect(result.userId, 'user-existing');
      expect(result.generatedPassword, isNull);
      expect(result.existingUserMessage, contains('already exists'));
    });

    test('grant duplicate platform_admins is success', () async {
      final http = _RecordingHttp(({
        required method,
        required uri,
        required headers,
        body,
      }) async {
        if (method == 'POST' && uri.path.endsWith('/rest/v1/platform_admins')) {
          return const SupabaseAdminHttpResponse(statusCode: 409, body: '');
        }
        fail('Unexpected ${method} ${uri.path}');
      });

      final service = PlatformAdminService(
        manifest: manifest,
        http: http,
        loadCanonical: (_) async => {
          'SUPABASE_URL': 'http://127.0.0.1:54321',
          'SUPABASE_SERVICE_ROLE_KEY': 'service-role-test',
        },
      );

      final result = await service.grant(
        ctx: ctx,
        userId: 'user-1',
      );
      expect(result.granted, isTrue);
      expect(result.userId, 'user-1');
    });

    test('missing service role throws', () async {
      final service = PlatformAdminService(
        manifest: manifest,
        http: _RecordingHttp(({
          required method,
          required uri,
          required headers,
          body,
        }) async {
          fail('should not call http');
        }),
        loadCanonical: (_) async => {
          'SUPABASE_URL': 'http://127.0.0.1:54321',
        },
      );

      expect(
        () => service.create(ctx: ctx, email: 'a@b.c', password: 'x'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_SERVICE_ROLE_KEY'),
          ),
        ),
      );
    });

    test('staging requires --yes', () async {
      final stagingCtx = manifest.context(
        profileId: 'default',
        environmentId: 'staging',
      );
      final service = PlatformAdminService(
        manifest: manifest,
        loadCanonical: (_) async => {
          'SUPABASE_URL': 'http://127.0.0.1:54321',
          'SUPABASE_SERVICE_ROLE_KEY': 'service-role-test',
        },
      );

      expect(
        () => service.create(
          ctx: stagingCtx,
          email: 'a@b.c',
          password: 'x',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('--yes'),
          ),
        ),
      );
    });
  });
}
