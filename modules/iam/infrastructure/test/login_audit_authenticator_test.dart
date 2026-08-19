import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/src/domain/auth/login_audit_authenticator.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  test('records platform login after successful Supabase auth sign-in', () async {
    final inner = _RecordingAuthenticator();
    final supabase = FakeIamRpcSupabase()
      ..registerHandler('record_my_platform_login', (_) async => null);
    final authenticator = LoginAuditAuthenticator(
      inner: inner,
      rpcClient: _rpcClient(supabase),
    );

    await authenticator.signIn(email: 'owner@vet45.com', password: 'secret');

    expect(inner.signedInEmail, 'owner@vet45.com');
    expect(
      supabase.calls.map((c) => c.functionName),
      contains('record_my_platform_login'),
    );
  });

  test('does not record platform login when credential sign-in fails', () async {
    final inner = _RecordingAuthenticator(failSignIn: true);
    final supabase = FakeIamRpcSupabase()
      ..registerHandler('record_my_platform_login', (_) async => null);
    final authenticator = LoginAuditAuthenticator(
      inner: inner,
      rpcClient: _rpcClient(supabase),
    );

    await expectLater(
      () => authenticator.signIn(email: 'owner@vet45.com', password: 'bad'),
      throwsA(isA<ApplicationException>()),
    );

    expect(supabase.calls, isEmpty);
  });
}

SupabaseSchemaRpcClient _rpcClient(FakeIamRpcSupabase supabase) {
  return SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'iam',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );
}

final class _RecordingAuthenticator implements IAuthenticator {
  _RecordingAuthenticator({this.failSignIn = false});

  final bool failSignIn;
  String? signedInEmail;

  @override
  String? get currentEmail => signedInEmail;

  @override
  String? get currentUserId => signedInEmail == null ? null : 'user-1';

  @override
  AuthSessionState get sessionState =>
      signedInEmail == null ? AuthSessionState.absent : AuthSessionState.active;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (failSignIn) {
      throw ApplicationException('Invalid login credentials');
    }
    signedInEmail = email;
  }

  @override
  Future<void> signOut() async {
    signedInEmail = null;
  }
}
