import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/scripted_auth.dart';

void main() {
  testWidgets('login page does not overflow when keyboard is open', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(393, 852),
            padding: EdgeInsets.only(top: 59, bottom: 34),
            viewInsets: EdgeInsets.only(bottom: 327),
          ),
          child: LoginPage(
            auth: ScriptedAuthRepository(),
            session: loginSession(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException()?.toString(), isNot(contains('overflowed')));
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}
