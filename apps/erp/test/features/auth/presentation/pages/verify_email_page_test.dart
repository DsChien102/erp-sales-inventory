import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:erp/features/auth/presentation/pages/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../receivable/presentation/receivable_test_harness.dart' show loadInterFont;
import '../../support/scripted_auth.dart';
import '../../support/test_router.dart';

void main() {
  setUpAll(loadInterFont);

  testWidgets('verify page sign out goes to login', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final log = <String>[];
    final session = loginSession(log: log);
    addTearDown(session.close);
    final harness = TestRouter(
      initial: '/verify-email',
      pages: {
        '/verify-email': VerifyEmailPage(
          email: 'lan@example.com',
          auth: ScriptedAuthRepository(),
          session: session,
        ),
      },
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(log, contains('signOut'));
    expect(find.text('LOGIN_PAGE'), findsOneWidget);
  });

  Future<ScriptedAuthRepository> pumpAt(
    WidgetTester tester,
    Size size, {
    String email = 'lan@example.com',
    double textScale = 1,
    bool homeInset = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    if (homeInset) {
      tester.view.padding = const FakeViewPadding(top: 30, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 30, bottom: 34);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = ScriptedAuthRepository();
    final session = loginSession();
    addTearDown(session.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: VerifyEmailPage(email: email, auth: auth, session: session),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('390: centered icon and title, sign out link at the bottom', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844), homeInset: true);
    expect(tester.getCenter(find.byType(FlowIcon)).dx, 195);
    expect(
      tester.getCenter(find.text('Xác minh email để tiếp tục')).dx,
      moreOrLessEquals(195, epsilon: 1),
    );
    final out = tester.getRect(find.widgetWithText(VButton, 'Đăng xuất'));
    expect(out.bottom, lessThanOrEqualTo(844 - 34));
    expect(out.bottom, greaterThan(844 - 34 - 24));
  });

  testWidgets('390: masked email is bold', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    final bold = find.byWidgetPredicate((w) {
      if (w is! RichText) return false;
      var found = false;
      w.text.visitChildren((span) {
        if (span is TextSpan &&
            span.text == 'l***@example.com' &&
            span.style?.fontWeight == FontWeight.w600) {
          found = true;
        }
        return true;
      });
      return found;
    });
    expect(bold, findsOneWidget);
  });

  testWidgets('1280: card 488 wide, vertically centered, sign out under the card', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1280, 800));
    final card = tester.getRect(find.byType(FlowCard));
    final out = tester.getRect(find.widgetWithText(VButton, 'Đăng xuất'));
    expect(card.width, 488);
    expect(out.top, greaterThanOrEqualTo(card.bottom));
    expect(card.top, moreOrLessEquals(800 - out.bottom, epsilon: 12));
  });

  testWidgets('resizing 900 → 700 keeps typed digits', (tester) async {
    final auth = await pumpAt(tester, const Size(900, 800));
    final code = find.descendant(
      of: find.byKey(const Key('otp_code_field')),
      matching: find.byType(TextField),
    );
    await tester.enterText(code, '123');
    await tester.pump();
    for (final size in const [Size(700, 800), Size(900, 800)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(code).controller?.text, '123');
    }
    expect(auth.otpCodes, isEmpty);
  });

  testWidgets('320 at text scale 2.0 and a 60-char email does not overflow', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const Size(320, 568),
      email: 'lan@${'tenmiencucdai' * 4}.example.com',
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
