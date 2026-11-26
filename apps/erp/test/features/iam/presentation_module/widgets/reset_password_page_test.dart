import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/validation/password_policy.dart';
import 'package:erp/features/iam/data/models/password_reset_result.dart';
import 'package:erp/features/iam/logic/password_reset_cubit.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/scripted_iam_repositories.dart';

Future<void> _settleRequest(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _enterResetCode(WidgetTester tester, String code) async {
  expect(find.byType(VVerificationCodeField), findsOneWidget);
  await tester.enterText(find.byType(TextField).first, code);
  await tester.pump();
}

Future<void> _verifyResetCode(WidgetTester tester, String code) async {
  await _enterResetCode(tester, code);
  final verifyButton = find.widgetWithText(VButton, 'Xác nhận mã');
  if (verifyButton.evaluate().isNotEmpty) {
    final button = tester.widget<VButton>(verifyButton);
    if (button.onPressed != null) {
      await tester.tap(verifyButton);
      await tester.pump();
    }
  }
  await _settleRequest(tester);
}

void main() {
  group('PasswordResetCubit', () {
    test('failed initial request retries Request command', () async {
      final auth = RecordingAuthRepository(
        failFirstRequest: true,
        clock: () => DateTime.utc(2026, 7, 31, 9),
      );
      final cubit = PasswordResetCubit(
        authRepository: auth,
        clock: () => DateTime.utc(2026, 7, 31, 9),
      );
      await cubit.request();
      await cubit.retry();
      expect(auth.calls.where((call) => call == 'requestMy'), hasLength(2));
      expect(auth.calls.where((call) => call.startsWith('resendMy')), isEmpty);
      await cubit.close();
    });

    test('public requestEmail uses by-email commands', () async {
      final auth = RecordingAuthRepository(
        clock: () => DateTime.utc(2026, 7, 31, 9),
      );
      final cubit = PasswordResetCubit(
        authRepository: auth,
        requestEmail: 'lan@example.com',
        clock: () => DateTime.utc(2026, 7, 31, 9),
      );
      await cubit.request();
      expect(auth.calls, ['requestByEmail:lan@example.com']);
      await cubit.close();
    });

    test('resend uses operationId returned by request', () async {
      final auth = RecordingAuthRepository(
        clock: () => DateTime.utc(2026, 7, 31, 9),
      );
      final cubit = PasswordResetCubit(
        authRepository: auth,
        clock: () => DateTime.utc(2026, 7, 31, 9),
      );
      await cubit.request();
      await cubit.resend();
      expect(auth.calls, contains('resendMy:op-1'));
      await cubit.close();
    });
  });

  testWidgets(
    'ResetPasswordPage requests reset, shows countdown, then resends',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var now = DateTime.utc(2026, 7, 31, 9);
      final auth = RecordingAuthRepository(
        clock: () => now,
        resendAfter: const Duration(seconds: 60),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ResetPasswordPage(
            authRepository: auth,
            clock: () => now,
          ),
        ),
      );
      await _settleRequest(tester);

      expect(auth.calls, contains('requestMy'));
      expect(
        find.textContaining('Mã 6 chữ số đã được gửi tới l***@example.com'),
        findsOneWidget,
      );
      expect(find.text('Gửi lại mã sau 00:60'), findsOneWidget);

      now = now.add(const Duration(seconds: 60));
      await tester.pump(const Duration(seconds: 1));

      final resendFinder = find.widgetWithText(VButton, 'Gửi lại mã');
      expect(resendFinder, findsOneWidget);
      await tester.tap(resendFinder);
      await _settleRequest(tester);

      expect(auth.calls, contains('resendMy:op-1'));
      expect(
        find.byWidgetPredicate(
          (w) => w is VButton && w.label.startsWith('Gửi lại mã sau 00:') && w.onPressed == null,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ResetPasswordPage stays on verify when verified=false',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = RecordingAuthRepository(verifyResult: false);

      await tester.pumpWidget(
        MaterialApp(
          home: ResetPasswordPage(authRepository: auth),
        ),
      );
      await _settleRequest(tester);

      await _verifyResetCode(tester, '123456');

      expect(auth.calls, contains('verifyMy'));
      expect(find.text('Xác minh email'), findsOneWidget);
      expect(find.text('Tạo mật khẩu mới'), findsNothing);
    },
  );

  testWidgets(
    'ResetPasswordPage advances when verified=true',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = RecordingAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ResetPasswordPage(authRepository: auth),
        ),
      );
      await _settleRequest(tester);

      await _verifyResetCode(tester, '123456');

      expect(auth.calls, contains('verifyMy'));
      expect(find.text('Tạo mật khẩu mới'), findsOneWidget);
    },
  );

  testWidgets(
    'ResetPasswordPage completes with typed result and pops true',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = RecordingAuthRepository();
      Object? popResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    popResult = await Navigator.of(context).push<Object?>(
                      MaterialPageRoute<Object?>(
                        builder: (_) => ResetPasswordPage(authRepository: auth),
                      ),
                    );
                  },
                  child: const Text('open-reset'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open-reset'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await _settleRequest(tester);

      await _verifyResetCode(tester, '123456');

      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(0), 'Password#123');
      await tester.enterText(passwordFields.at(1), 'Password#123');
      await tester.pump();

      await tester.tap(find.widgetWithText(VButton, 'Đặt lại mật khẩu'));
      await _settleRequest(tester);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(auth.calls.where((call) => call == 'completeMy'), hasLength(1));
      expect(popResult, isTrue);
      expect(find.textContaining('Password#123'), findsNothing);
      expect(find.text('123456'), findsNothing);
      expect(find.textContaining('op-1'), findsNothing);
    },
  );

  testWidgets(
    'ResetPasswordPage (TA-D-03) offline validation flow without iamModule',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordPage(emailMasked: 'mi***@gmail.com'),
        ),
      );

      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
      expect(find.text('Xác minh email'), findsOneWidget);
      expect(
        find.textContaining('Mã 6 chữ số đã được gửi tới mi***@gmail.com'),
        findsOneWidget,
      );
      expect(find.byType(VVerificationCodeField), findsOneWidget);

      final verifyButtonFinder = find.widgetWithText(VButton, 'Xác nhận mã');
      expect(verifyButtonFinder, findsOneWidget);

      var verifyBtnWidget = tester.widget<VButton>(verifyButtonFinder);
      expect(verifyBtnWidget.onPressed, isNull);

      await _enterResetCode(tester, '12345');
      verifyBtnWidget = tester.widget<VButton>(verifyButtonFinder);
      expect(verifyBtnWidget.onPressed, isNull);

      await _verifyResetCode(tester, '123456');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.text('Tạo mật khẩu mới'), findsOneWidget);

      final resetButtonFinder = find.widgetWithText(VButton, 'Đặt lại mật khẩu');
      expect(resetButtonFinder, findsOneWidget);

      var resetBtnWidget = tester.widget<VButton>(resetButtonFinder);
      expect(resetBtnWidget.onPressed, isNull);

      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(0), '123');
      await tester.pump();

      resetBtnWidget = tester.widget<VButton>(resetButtonFinder);
      expect(resetBtnWidget.onPressed, isNull);

      await tester.enterText(passwordFields.at(1), '456');
      await tester.pump();

      resetBtnWidget = tester.widget<VButton>(resetButtonFinder);
      expect(resetBtnWidget.onPressed, isNotNull);

      await tester.tap(resetButtonFinder);
      await tester.pump();

      expect(
        find.text(PasswordPolicy.violationMessage),
        findsOneWidget,
      );
      expect(find.text('Mật khẩu nhập lại không trùng khớp'), findsOneWidget);

      await tester.enterText(passwordFields.at(0), 'Password123!');
      await tester.enterText(passwordFields.at(1), 'Password123!');
      await tester.pump();

      expect(find.text(PasswordPolicy.violationMessage), findsNothing);
      expect(find.text('Mật khẩu nhập lại không trùng khớp'), findsNothing);
    },
  );

  testWidgets('request failure shows retry', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = RecordingAuthRepository(failFirstRequest: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: ResetPasswordPage(authRepository: auth),
      ),
    );
    await _settleRequest(tester);

    expect(find.text('Không gửi được mã'), findsWidgets);
    expect(find.widgetWithText(VButton, 'Thử lại'), findsOneWidget);

    await tester.tap(find.widgetWithText(VButton, 'Thử lại'));
    await _settleRequest(tester);

    expect(auth.calls.where((c) => c == 'requestMy'), hasLength(2));
    expect(find.text('Xác minh email'), findsOneWidget);
  });

  testWidgets('six digits verify once', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = RecordingAuthRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: ResetPasswordPage(authRepository: auth),
      ),
    );
    await _settleRequest(tester);

    await _enterResetCode(tester, '123456');
    await _settleRequest(tester);

    expect(auth.calls.where((c) => c == 'verifyMy'), hasLength(1));
  });

  testWidgets('resend failure shows a toast', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var now = DateTime.utc(2026, 7, 31, 9);
    final auth = _T0AuthRepository(
      clock: () => now,
      resendAfter: const Duration(seconds: 60),
      resendError: const AppException(AppErrorCode.unknown),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: ResetPasswordPage(authRepository: auth, clock: () => now),
      ),
    );
    await _settleRequest(tester);

    now = now.add(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.widgetWithText(VButton, 'Gửi lại mã'));
    await _settleRequest(tester);

    expect(find.byType(VToast), findsOneWidget);
    expect(
      tester.widget<VToast>(find.byType(VToast)).title,
      'Không thể tiếp tục',
    );
  });

  testWidgets('submitting shows the overlay', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final verifyCompleter = Completer<PasswordResetVerifyResult>();
    final auth = _T0AuthRepository(verifyCompleter: verifyCompleter);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: ResetPasswordPage(authRepository: auth),
      ),
    );
    await _settleRequest(tester);

    await _enterResetCode(tester, '123456');
    await tester.pump();

    expect(find.byType(VLoading), findsOneWidget);

    await tester.tap(
      find.widgetWithText(VButton, 'Xác nhận mã'),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(auth.calls.where((c) => c == 'verifyMy'), hasLength(1));

    verifyCompleter.complete(const PasswordResetVerifyResult(verified: true));
    await _settleRequest(tester);
  });
}

final class _T0AuthRepository extends RecordingAuthRepository {
  _T0AuthRepository({
    super.clock,
    super.resendAfter,
    this.resendError,
    this.verifyCompleter,
  });

  final Object? resendError;
  final Completer<PasswordResetVerifyResult>? verifyCompleter;

  @override
  Future<PasswordResetRequestResult> resendMyPasswordReset(
    String operationId,
  ) async {
    calls.add('resendMy:$operationId');
    if (resendError != null) throw resendError!;
    return super.resendMyPasswordReset(operationId);
  }

  @override
  Future<PasswordResetVerifyResult> verifyMyPasswordReset(
    String operationId,
    String code,
  ) async {
    calls.add('verifyMy');
    if (verifyCompleter != null) return verifyCompleter!.future;
    return PasswordResetVerifyResult(verified: verifyResult);
  }
}
