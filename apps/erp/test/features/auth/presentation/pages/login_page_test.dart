import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/auth/logic/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/scripted_auth.dart';

void main() {
  testWidgets('network login failure shows an inline banner without a toast', (
    tester,
  ) async {
    final auth = ScriptedAuthRepository(
      signInError: const AppException('NETWORK_ERROR'),
    );
    final session = loginSession();
    final cubit = LoginCubit(auth: auth, session: session);
    addTearDown(cubit.close);
    addTearDown(session.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: LoginPage(auth: auth, session: session, cubit: cubit),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'lan@example.com');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();

    expect(find.byType(VBanner), findsOneWidget);
    expect(find.byType(VToast), findsNothing);
  });

  testWidgets('forgot password with empty email shows only the field error', (
    tester,
  ) async {
    final session = loginSession();
    addTearDown(session.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: LoginPage(
          auth: ScriptedAuthRepository(),
          session: session,
        ),
      ),
    );

    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pump();

    expect(find.text('Vui lòng nhập email trước khi đặt lại mật khẩu'), findsOneWidget);
    expect(find.byType(VToast), findsNothing);
  });

  testWidgets('auth links satisfy labeled and iOS tap target guidelines', (
    tester,
  ) async {
    final session = loginSession();
    addTearDown(session.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: LoginPage(
          auth: ScriptedAuthRepository(),
          session: session,
        ),
      ),
    );

    final semanticsHandle = tester.ensureSemantics();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('V45'), findsNothing);
    for (final label in [
      'Quên mật khẩu?',
      'Đăng nhập',
      'Đăng ký cửa hàng mới',
      'Kích hoạt tài khoản',
    ]) {
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(label))),
        findsAtLeastNWidgets(1),
      );
    }
    expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    semanticsHandle.dispose();
  });

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
    expect(find.text('Đăng ký cửa hàng mới'), findsOneWidget);
  });
}
