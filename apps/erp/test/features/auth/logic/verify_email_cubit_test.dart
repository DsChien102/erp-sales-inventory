import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/session_controller.dart';
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

  test('resend failure is not a code failure', () async {
    final auth = ScriptedAuthRepository()
      ..resendError = const AppException(AppErrorCode.network);
    final session = loginSession();
    final cubit = VerifyEmailCubit(
      auth: auth,
      session: session,
      email: 'lan@example.com',
      allowImmediateResend: true,
    );

    await cubit.resend();

    expect(cubit.state.failure, isNull);
    expect(cubit.state.resendFailure, isNotNull);
    expect(cubit.state.resending, isFalse);
    expect(cubit.state.canResend, isTrue);
    await cubit.close();
    await session.close();
  });

  test('verify and resend clear resendFailure', () async {
    final auth = ScriptedAuthRepository()
      ..resendError = const AppException(AppErrorCode.network);
    final session = loginSession();
    final cubit = VerifyEmailCubit(
      auth: auth,
      session: session,
      email: 'lan@example.com',
      allowImmediateResend: true,
    );

    await cubit.resend();
    expect(cubit.state.resendFailure, isNotNull);
    final seen = <String?>[];
    final sub = cubit.stream.listen((s) => seen.add(s.resendFailure));
    await cubit.resend();
    await Future<void>.delayed(Duration.zero);
    // lần hai: bắt đầu xoá (null) rồi đặt lại
    expect(seen.first, isNull);
    expect(seen.last, isNotNull);

    await cubit.verify('123456');
    expect(cubit.state.resendFailure, isNull);
    await sub.cancel();
    await cubit.close();
    await session.close();
  });

  testWidgets('resending keeps the code field and Xác minh usable', (tester) async {
    final gate = Completer<void>();
    final auth = _HangingResend(gate);
    final session = loginSession();
    addTearDown(session.close);
    await tester.pumpWidget(_host(auth, session, allowImmediateResend: true));
    await tester.pump();

    await tester.tap(find.byKey(const Key('signup_resend')));
    await tester.pump();

    final verify = tester.widget<VButton>(find.byKey(const Key('signup_verify')));
    expect(verify.isLoading, isFalse);
    expect(verify.onPressed, isNotNull);
    final code = tester.widget<VVerificationCodeField>(
      find.byType(VVerificationCodeField),
    );
    expect(code.enabled, isTrue);
    expect(
      tester.widget<VButton>(find.byKey(const Key('signup_resend'))).onPressed,
      isNull,
    );
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('resend failure shows a toast each time and keeps cells neutral', (
    tester,
  ) async {
    final auth = ScriptedAuthRepository()
      ..resendError = const AppException(AppErrorCode.network);
    final session = loginSession();
    addTearDown(session.close);
    await tester.pumpWidget(_host(auth, session, allowImmediateResend: true));
    await tester.pump();

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('signup_resend')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(VToast), findsOneWidget, reason: 'lần ${i + 1}');
      expect(find.byType(VFieldError), findsNothing);
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
          .clearSnackBars();
      await tester.pumpAndSettle();
      expect(find.byType(VToast), findsNothing);
    }
    expect(auth.resentEmails, hasLength(2));
  });

  testWidgets('countdown is text, then a link', (tester) async {
    var now = DateTime.utc(2026, 11, 25, 9);
    final session = loginSession();
    addTearDown(session.close);
    await tester.pumpWidget(
      _host(ScriptedAuthRepository(), session, clock: () => now),
    );
    await tester.pump();

    expect(find.text('Gửi lại mã sau 01:00'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Gửi lại mã'), findsNothing);

    now = now.add(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 1));
    final link = find.widgetWithText(VButton, 'Gửi lại mã');
    expect(link, findsOneWidget);
    expect(tester.widget<VButton>(link).onPressed, isNotNull);
  });

  testWidgets('verify button comes before resend', (tester) async {
    final session = loginSession();
    addTearDown(session.close);
    await tester.pumpWidget(
      _host(ScriptedAuthRepository(), session, allowImmediateResend: true),
    );
    await tester.pump();

    final verifyY = tester.getTopLeft(find.byKey(const Key('signup_verify'))).dy;
    final resendY = tester.getTopLeft(find.byKey(const Key('signup_resend'))).dy;
    expect(verifyY, lessThan(resendY));
  });
}

Widget _host(
  ScriptedAuthRepository auth,
  SessionController session, {
  bool allowImmediateResend = false,
  DateTime Function()? clock,
}) {
  return MaterialApp(
    theme: VTheme.lightTheme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: VerifyEmailView(
          email: 'lan@example.com',
          auth: auth,
          session: session,
          allowImmediateResend: allowImmediateResend,
          clock: clock,
        ),
      ),
    ),
  );
}

class _HangingResend extends ScriptedAuthRepository {
  _HangingResend(this.gate);
  final Completer<void> gate;

  @override
  Future<void> resendSignupOtp(String email) async {
    await gate.future;
    return super.resendSignupOtp(email);
  }
}
