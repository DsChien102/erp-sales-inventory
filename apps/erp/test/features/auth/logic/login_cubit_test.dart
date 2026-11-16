import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/features/auth/logic/login_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_auth.dart';

/// `signIn` chờ [gate] để test đóng cubit giữa lúc đang đăng nhập.
class _GatedAuthRepository extends ScriptedAuthRepository {
  final gate = Completer<String>();

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) => gate.future;
}

void main() {
  group('LoginCubit khi bị đóng giữa lúc signIn', () {
    test('không emit lại và vẫn gắn phiên khi signIn thành công', () async {
      final auth = _GatedAuthRepository();
      final session = loginSession(authenticated: false);
      addTearDown(session.close);
      final cubit = LoginCubit(auth: auth, session: session);

      final pending = cubit.submit(email: 'lan@example.com', password: 'pw');
      await cubit.close();
      auth.gate.complete('user-1');

      await expectLater(pending, completes);
      expect(session.state.authStatus, AuthStatus.signedIn);
      expect(session.state.userId, 'user-1');
    });

    test('không emit lại khi signIn thất bại sau khi đóng', () async {
      final auth = _GatedAuthRepository();
      final session = loginSession();
      addTearDown(session.close);
      final cubit = LoginCubit(auth: auth, session: session);

      final pending = cubit.submit(email: 'lan@example.com', password: 'pw');
      await cubit.close();
      auth.gate.completeError(const AppException('AUTH_REQUIRED'));

      await expectLater(pending, completes);
    });
  });
}
