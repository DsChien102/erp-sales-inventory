import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/auth/logic/verify_email_cubit.dart';
import 'package:erp/features/auth/presentation/widgets/verify_email_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../support/scripted_auth.dart';

void main() {
  testWidgets('entering six OTP digits verifies exactly once', (tester) async {
    final auth = ScriptedAuthRepository();
    final session = loginSession();
    addTearDown(session.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: VerifyEmailView(
            email: 'lan@example.com',
            auth: auth,
            session: session,
          ),
        ),
      ),
    );
    await tester.pump();

    final field = find.descendant(
      of: find.byKey(const Key('otp_code_field')),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, '123456');
    await tester.pumpAndSettle();

    expect(auth.otpCodes, ['123456']);
  });

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

  test('resend during the security window shows a countdown instead of an error', () async {
    var now = DateTime.utc(2026, 10, 10, 9);
    final auth = ScriptedAuthRepository()
      ..resendError = const AppException(
        AppErrorCode.resendCooldown,
        details: {'seconds': 17},
      );
    final session = loginSession();
    final cubit = VerifyEmailCubit(
      auth: auth,
      session: session,
      email: 'lan@example.com',
      clock: () => now,
      allowImmediateResend: true,
    );

    await cubit.resend();

    expect(cubit.state.failure, isNull);
    expect(cubit.state.canResend, isFalse);
    expect(cubit.state.remaining, const Duration(seconds: 17));

    await cubit.close();
    await session.close();
  });
}
