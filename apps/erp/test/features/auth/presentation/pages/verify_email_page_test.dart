import 'package:erp/features/auth/presentation/pages/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/scripted_auth.dart';
import '../../support/test_router.dart';

void main() {
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
}
