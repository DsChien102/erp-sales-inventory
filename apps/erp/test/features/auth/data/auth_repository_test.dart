import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';

class _Rpc extends SupabaseRpc {
  _Rpc(this.payloads)
    : super(
        SupabaseClient(
          'http://127.0.0.1',
          'anon',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final Map<String, Map<String, dynamic>> payloads;
  final calls = <String>[];

  @override
  Future<Map<String, dynamic>> firstRow(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    calls.add(fn);
    final row = payloads[fn];
    if (row == null) {
      throw const AppException(AppErrorCode.notFound);
    }
    return row;
  }

  @override
  Future<dynamic> call(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    calls.add(fn);
    return payloads[fn];
  }
}

class _Auth extends Mock implements GoTrueClient {}

class _User extends Mock implements User {}

void main() {
  late _Auth auth;
  late _User user;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
  });

  setUp(() {
    auth = _Auth();
    user = _User();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.email).thenReturn('lan@gmail.com');
    when(() => user.emailConfirmedAt).thenReturn('2026-01-01T00:00:00Z');
  });

  test('requestMyPasswordReset masks the signed-in email', () async {
    final rpc = _Rpc({
      'begin_password_reset_operation': {
        'operation_id': 'op-1',
        'expires_at': '2026-07-31T09:10:00Z',
        'resend_available_at': '2026-07-31T09:01:00Z',
      },
    });
    final repository = AuthRepository(rpc: rpc, auth: auth);

    final result = await repository.requestMyPasswordReset();

    expect(result.maskedEmail, 'l***@gmail.com');
    expect(result.operationId, 'op-1');
  });

  test('completeMyPasswordReset rejects an operation that is not verified', () async {
    final rpc = _Rpc({
      'get_password_reset_operation': {'status': 'pending'},
    });
    final repository = AuthRepository(rpc: rpc, auth: auth);

    expect(
      repository.completeMyPasswordReset('op-1', 'Password1!'),
      throwsA(
        isA<AppException>().having((error) => error.code, 'code', AppErrorCode.stateChanged),
      ),
    );
  });

  test('completeMyPasswordReset maps weak_password to PASSWORD_POLICY_VIOLATION', () async {
    final rpc = _Rpc({
      'get_password_reset_operation': {'status': 'verified'},
    });
    when(() => auth.updateUser(any())).thenThrow(
      const AuthException('password is too weak', code: 'weak_password'),
    );
    final repository = AuthRepository(rpc: rpc, auth: auth);

    expect(
      repository.completeMyPasswordReset('op-1', 'Password1!'),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'PASSWORD_POLICY_VIOLATION',
        ),
      ),
    );
  });
}
