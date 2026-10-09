import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/auth/logic/verify_email_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_auth.dart';

void main() {
  test('a wrong code shows the OTP message', () async {
    final auth = ScriptedAuthRepository()..verifyError = const AppException('OTP_INVALID');
    final session = loginSession();
    final cubit = VerifyEmailCubit(
      auth: auth,
      session: session,
      email: 'lan@example.com',
    );

    await cubit.verify('123456');

    expect(cubit.state.failure, 'Mã xác minh không đúng hoặc đã hết hạn.');
    expect(cubit.state.verified, isFalse);
    await cubit.close();
    await session.close();
  });

  test('resend stays locked for 60 seconds', () async {
    var now = DateTime.utc(2026, 10, 9, 1);
    final auth = ScriptedAuthRepository();
    final session = loginSession();
    final cubit = VerifyEmailCubit(
      auth: auth,
      session: session,
      email: 'lan@example.com',
      clock: () => now,
    );

    expect(cubit.state.canResend, isFalse);
    await cubit.resend();
    expect(auth.resentEmails, isEmpty);

    now = now.add(const Duration(seconds: 60));
    cubit.onTick();
    expect(cubit.state.canResend, isTrue);

    await cubit.resend();
    expect(auth.resentEmails, ['lan@example.com']);
    expect(cubit.state.canResend, isFalse);
    expect(cubit.state.remaining, const Duration(seconds: 60));

    await cubit.close();
    await session.close();
  });

  test('allowImmediateResend unlocks resend immediately', () async {
    final auth = ScriptedAuthRepository();
    final session = loginSession();
    final cubit = VerifyEmailCubit(
      auth: auth,
      session: session,
      email: 'lan@example.com',
      allowImmediateResend: true,
    );

    expect(cubit.state.canResend, isTrue);
    await cubit.resend();
    expect(auth.resentEmails, ['lan@example.com']);

    await cubit.close();
    await session.close();
  });
}
