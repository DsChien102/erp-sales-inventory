import 'dart:async';

import 'package:erp/core/widgets/app_logo.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/auth/logic/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/scripted_auth.dart';
import '../../support/test_router.dart';

void main() {
  testWidgets('login shows the app logo instead of V45', (tester) async {
    final auth = ScriptedAuthRepository();
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

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('V45'), findsNothing);
  });

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

  group('hành vi giữ nguyên khi đổi bố cục', () {
    setUp(() {});

    Future<TestRouter> pumpLogin(
      WidgetTester tester, {
      ScriptedAuthRepository? auth,
      String? prefilledEmail,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = auth ?? ScriptedAuthRepository();
      final session = loginSession();
      addTearDown(session.close);
      final harness = TestRouter(
        initial: '/login',
        pages: {
          '/login': LoginPage(
            auth: repo,
            session: session,
            prefilledEmail: prefilledEmail,
          ),
        },
      );
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      return harness;
    }

    testWidgets('typing clears email error and banner', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.text('Đăng nhập').last);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'a');
      await tester.pump();
      expect(find.text('Vui lòng nhập email'), findsNothing);
    });

    testWidgets('enter in password submits', (tester) async {
      final auth = ScriptedAuthRepository();
      await pumpLogin(tester, auth: auth);
      await tester.enterText(find.byType(TextField).at(0), 'lan@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(auth.signIns, hasLength(1));
      expect(auth.signIns.single.email, 'lan@example.com');
    });

    testWidgets('submitting disables every action', (tester) async {
      final gate = Completer<void>();
      final auth = _HangingSignIn(gate);
      final harness = await pumpLogin(tester, auth: auth);
      await tester.enterText(find.byType(TextField).at(0), 'lan@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.text('Đăng nhập').last);
      await tester.pump();

      for (final label in [
        'Đăng ký cửa hàng mới',
        'Kích hoạt tài khoản',
        'Quên mật khẩu?',
      ]) {
        await tester.tap(find.text(label), warnIfMissed: false);
        await tester.pump();
      }
      expect(find.text('SIGNUP_PAGE'), findsNothing);
      expect(find.text('INVITATION_PAGE'), findsNothing);
      expect(find.text('RESET_PAGE'), findsNothing);
      expect(harness.extras.containsKey('/signup'), isFalse);
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('prefilled email updates', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = ScriptedAuthRepository();
      final session = loginSession();
      addTearDown(session.close);
      Widget host(String email) => MaterialApp(
        theme: VTheme.lightTheme,
        home: LoginPage(auth: auth, session: session, prefilledEmail: email),
      );
      await tester.pumpWidget(host('a@example.com'));
      await tester.pumpAndSettle();
      expect(find.text('a@example.com'), findsOneWidget);
      await tester.pumpWidget(host('b@example.com'));
      await tester.pumpAndSettle();
      expect(find.text('b@example.com'), findsOneWidget);
      expect(find.text('a@example.com'), findsNothing);
    });
  });
}

class _HangingSignIn extends ScriptedAuthRepository {
  _HangingSignIn(this.gate);
  final Completer<void> gate;

  @override
  Future<String> signIn({required String email, required String password}) async {
    await gate.future;
    return super.signIn(email: email, password: password);
  }
}
