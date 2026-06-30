import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';

class _FakeGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSupabaseClient implements SupabaseClient {
  final _FakeGoTrueClient _auth = _FakeGoTrueClient();

  @override
  GoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('initializeForTesting wires IAM module and access services', () async {
    final runtime = await IamStartup.initializeForTesting(
      supabase: _FakeSupabaseClient(),
    );

    expect(runtime.module, isA<IIamModule>());
    expect(runtime.executionContext, isA<IExecutionContext>());
    expect(runtime.permissionChecker, isA<IPermissionChecker>());
    expect(runtime.tenantAccessChecker, isA<ITenantAccessChecker>());
    expect(runtime.session.userId, isNull);
  });
}
