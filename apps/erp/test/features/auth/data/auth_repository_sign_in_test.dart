import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';

class _Rpc extends SupabaseRpc {
  _Rpc()
    : super(
        SupabaseClient(
          'http://127.0.0.1',
          'anon',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final calls = <String>[];
  Object? assertError;
  Object? recordError;

  @override
  Future<dynamic> call(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    calls.add(fn);
    if (fn == 'assert_my_platform_access' && assertError != null) {
      throw assertError!;
    }
    if (fn == 'record_my_platform_login' && recordError != null) {
      throw recordError!;
    }
    return null;
  }
}

class _Auth extends Mock implements GoTrueClient {}

class _User extends Mock implements User {}

void main() {
  late _Rpc rpc;
  late _Auth auth;
  late AuthRepository repository;

  setUp(() {
    rpc = _Rpc();
    auth = _Auth();
    repository = AuthRepository(rpc: rpc, auth: auth);
    final user = _User();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);
    when(
      () => auth.signInWithPassword(email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) async => AuthResponse());
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  test('suspended platform user signs out and throws', () async {
    rpc.assertError = const AppException(
      AppErrorCode.unknown,
      serverMessage: 'blocked: PLATFORM_USER_SUSPENDED',
    );

    await expectLater(
      repository.signIn(email: 'a@b.c', password: 'secret'),
      throwsA(
        isA<AppException>().having((error) => error.code, 'code', 'PLATFORM_USER_SUSPENDED'),
      ),
    );
    verify(() => auth.signOut()).called(1);
  });

  test('other assert_my_platform_access errors still sign in', () async {
    rpc.assertError = const AppException(AppErrorCode.unknown);

    final userId = await repository.signIn(email: 'a@b.c', password: 'secret');

    expect(userId, 'user-1');
    verifyNever(() => auth.signOut());
    expect(rpc.calls, contains('record_my_platform_login'));
  });

  test('record_my_platform_login errors still sign in', () async {
    rpc.recordError = const AppException(AppErrorCode.unknown);

    final userId = await repository.signIn(email: 'a@b.c', password: 'secret');

    expect(userId, 'user-1');
    expect(rpc.calls, contains('record_my_platform_login'));
  });
}
