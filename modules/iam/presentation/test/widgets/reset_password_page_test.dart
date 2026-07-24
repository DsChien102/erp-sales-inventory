import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets(
      'ResetPasswordPage (TA-D-03) flows through Step 1 verify code to Step 2 create new password with error validation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResetPasswordPage(),
      ),
    );

    // STEP 1 Verification
    expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
    expect(find.text('Xác minh email'), findsOneWidget);
    expect(
      find.textContaining('Mã 6 chữ số đã được gửi tới mi***@gmail.com'),
      findsOneWidget,
    );

    final verifyButtonFinder = find.widgetWithText(VButton, 'Xác nhận mã');
    expect(verifyButtonFinder, findsOneWidget);

    // Verify button disabled when code empty
    var verifyBtnWidget = tester.widget<VButton>(verifyButtonFinder);
    expect(verifyBtnWidget.onPressed, isNull);

    // Enter verification code
    final codeField = find.byType(TextField);
    await tester.enterText(codeField.first, '123456');
    await tester.pump();

    // Verify button enabled
    verifyBtnWidget = tester.widget<VButton>(verifyButtonFinder);
    expect(verifyBtnWidget.onPressed, isNotNull);

    // Tap verify button to advance to STEP 2 (after 800ms loading)
    await tester.tap(verifyButtonFinder);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // STEP 2 Create New Password
    expect(find.text('Tạo mật khẩu mới'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Mật khẩu mới'),
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('Nhập lại mật khẩu mới'),
      ),
      findsOneWidget,
    );
    expect(find.text('Quy tắc mật khẩu'), findsOneWidget);

    final resetButtonFinder = find.widgetWithText(VButton, 'Đặt lại mật khẩu');
    expect(resetButtonFinder, findsOneWidget);

    // Verify reset button is initially disabled (both fields empty)
    var resetBtnWidget = tester.widget<VButton>(resetButtonFinder);
    expect(resetBtnWidget.onPressed, isNull);

    // Enter only field 1
    final passwordFields = find.byType(TextField);
    await tester.enterText(passwordFields.at(0), '123');
    await tester.pump();

    // Verify button is STILL disabled
    resetBtnWidget = tester.widget<VButton>(resetButtonFinder);
    expect(resetBtnWidget.onPressed, isNull);

    // Enter field 2
    await tester.enterText(passwordFields.at(1), '456');
    await tester.pump();

    // Verify reset button is NOW enabled (both fields filled)
    resetBtnWidget = tester.widget<VButton>(resetButtonFinder);
    expect(resetBtnWidget.onPressed, isNotNull);

    // Tap Reset Password to trigger validation errors
    await tester.tap(resetButtonFinder);
    await tester.pump();

    // Verify error text is displayed
    expect(
        find.text('Mật khẩu phải chứa tối thiểu 8 ký tự'), findsOneWidget);
    expect(find.text('Mật khẩu nhập lại không trùng khớp'), findsOneWidget);

    // Now fix passwords to valid >= 8 chars and matching
    await tester.enterText(passwordFields.at(0), 'Password123');
    await tester.enterText(passwordFields.at(1), 'Password123');
    await tester.pump();

    // Errors should clear
    expect(find.text('Mật khẩu phải chứa tối thiểu 8 ký tự'), findsNothing);
    expect(find.text('Mật khẩu nhập lại không trùng khớp'), findsNothing);
  });
}
