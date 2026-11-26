import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/features/iam/data/models/password_reset_result.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../receivable/presentation/receivable_test_harness.dart';
import '../support/scripted_iam_repositories.dart';

Future<void> _captureReset(
  WidgetTester tester, {
  required int width,
  required String name,
  required Widget page,
  Future<void> Function()? act,
}) async {
  final phone = width == 390;
  final view = tester.view;
  view.physicalSize = phone ? const Size(390, 844) : const Size(1280, 800);
  view.devicePixelRatio = 1;
  if (phone) {
    view.padding = const FakeViewPadding(top: 30, bottom: 34);
    view.viewPadding = const FakeViewPadding(top: 30, bottom: 34);
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      home: RepaintBoundary(key: key, child: page),
    ),
  );
  await tester.pump();
  await tester.pump();
  if (act != null) await act();
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(
      '${repoRoot()}/docs/refactor/plans/P10/img/10-8f/flutter-$name-$width.png',
    ),
  );
}

final class _GoldenAuthRepository extends RecordingAuthRepository {
  _GoldenAuthRepository({
    super.failFirstRequest,
    super.clock,
    super.resendAfter,
    this.verifyError,
  });

  final Object? verifyError;

  @override
  Future<PasswordResetVerifyResult> verifyMyPasswordReset(
    String operationId,
    String code,
  ) async {
    calls.add('verifyMy');
    if (verifyError != null) throw verifyError!;
    return const PasswordResetVerifyResult(verified: true);
  }
}

void main() {
  setUpAll(() async {
    await loadInterFont();
  });

  for (final width in const [390, 1280]) {
    testWidgets('reset__verify $width', (tester) async {
      final now = DateTime.utc(2026, 7, 31, 9);
      await _captureReset(
        tester,
        width: width,
        name: 'reset__verify',
        page: ResetPasswordPage(
          authRepository: _GoldenAuthRepository(
            clock: () => now,
            resendAfter: const Duration(seconds: 59),
          ),
          clock: () => now,
        ),
      );
    });

    testWidgets('reset__verify-wrong $width', (tester) async {
      final now = DateTime.utc(2026, 7, 31, 9);
      await _captureReset(
        tester,
        width: width,
        name: 'reset__verify-wrong',
        page: ResetPasswordPage(
          authRepository: _GoldenAuthRepository(
            clock: () => now,
            resendAfter: const Duration(seconds: 31),
            verifyError: const AppException(IamBlockedCodes.resetCodeInvalid),
          ),
          clock: () => now,
        ),
        act: () async {
          await tester.enterText(find.byType(TextField).first, '482915');
          await tester.pump();
          await tester.pump();
        },
      );
    });

    testWidgets('reset__resend-ready $width', (tester) async {
      final now = DateTime.utc(2026, 7, 31, 9);
      await _captureReset(
        tester,
        width: width,
        name: 'reset__resend-ready',
        page: ResetPasswordPage(
          authRepository: _GoldenAuthRepository(
            clock: () => now,
            resendAfter: Duration.zero,
          ),
          clock: () => now,
        ),
      );
    });

    testWidgets('reset__create $width', (tester) async {
      final now = DateTime.utc(2026, 7, 31, 9);
      await _captureReset(
        tester,
        width: width,
        name: 'reset__create',
        page: ResetPasswordPage(
          authRepository: _GoldenAuthRepository(clock: () => now),
          clock: () => now,
        ),
        act: () async {
          await tester.enterText(find.byType(TextField).first, '482915');
          await tester.pump();
          await tester.pump();
        },
      );
    });

    testWidgets('reset__create-errors $width', (tester) async {
      final now = DateTime.utc(2026, 7, 31, 9);
      await _captureReset(
        tester,
        width: width,
        name: 'reset__create-errors',
        page: ResetPasswordPage(
          authRepository: _GoldenAuthRepository(clock: () => now),
          clock: () => now,
        ),
        act: () async {
          await tester.enterText(find.byType(TextField).first, '482915');
          await tester.pump();
          await tester.pump();
          final fields = find.byType(TextField);
          await tester.enterText(fields.at(0), 'abc');
          await tester.enterText(fields.at(1), 'abcd');
          await tester.pump();
          await tester.tap(find.widgetWithText(VButton, 'Đặt lại mật khẩu'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
        },
      );
    });

    testWidgets('reset__request-failed $width', (tester) async {
      final now = DateTime.utc(2026, 7, 31, 9);
      await _captureReset(
        tester,
        width: width,
        name: 'reset__request-failed',
        page: ResetPasswordPage(
          authRepository: _GoldenAuthRepository(
            failFirstRequest: true,
            clock: () => now,
          ),
          clock: () => now,
        ),
      );
    });
  }
}
