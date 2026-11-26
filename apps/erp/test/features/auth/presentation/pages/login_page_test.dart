import 'dart:async';

import 'package:erp/core/widgets/app_logo.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/auth/logic/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

  group('bố cục iPhone / web (10-8e)', () {
    Future<void> pumpAt(
      WidgetTester tester,
      Size size, {
      String? organizationName,
      bool showSuccessBanner = false,
      bool passwordResetSuccess = false,
      ScriptedAuthRepository? auth,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final session = loginSession();
      addTearDown(session.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: LoginPage(
            auth: auth ?? ScriptedAuthRepository(),
            session: session,
            organizationName: organizationName,
            showSuccessBanner: showSuccessBanner,
            passwordResetSuccess: passwordResetSuccess,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('390 uses the narrow layout', (tester) async {
      await pumpAt(tester, const Size(390, 844));
      expect(find.byKey(const Key('login_wide_panel')), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('login_signup'))).height,
        greaterThanOrEqualTo(60),
      );
    });

    testWidgets('1280 footer reads © Mosaic Retail only', (tester) async {
      await pumpAt(tester, const Size(1280, 800));
      expect(find.text('© Mosaic Retail'), findsOneWidget);
      expect(find.textContaining('Phiên bản Mobile'), findsNothing);
    });

    testWidgets('1280 splits 42 / 58', (tester) async {
      await pumpAt(tester, const Size(1280, 800));
      final panel = tester.getRect(find.byKey(const Key('login_wide_panel')));
      final form = tester.getRect(find.byKey(const Key('login_wide_form')));
      expect(panel.width, moreOrLessEquals(537.6, epsilon: 1));
      expect(panel.height, 800);
      expect(form.width, moreOrLessEquals(400, epsilon: 0.01));
      expect(
        form.center.dx,
        moreOrLessEquals(panel.right + (1280 - panel.right) / 2, epsilon: 1),
      );
      expect(
        tester.getSize(find.byType(VEmailField)).width,
        moreOrLessEquals(336, epsilon: 0.01),
      );
    });

    testWidgets('1280: password label row is 32 tall', (tester) async {
      await pumpAt(tester, const Size(1280, 800));
      final link = tester.getRect(find.widgetWithText(VButton, 'Quên mật khẩu?'));
      expect(link.height, 32);
      expect(link.bottom, tester.getRect(find.byType(VPasswordField)).top);
    });

    testWidgets('860 stacks the brand strip', (tester) async {
      await pumpAt(tester, const Size(860, 800));
      final panel = tester.getRect(find.byKey(const Key('login_wide_panel')));
      final form = tester.getRect(find.byKey(const Key('login_wide_form')));
      expect(panel.width, 860);
      expect(panel.bottom, lessThanOrEqualTo(form.top));
    });

    testWidgets('844x390 landscape scrolls to the last action', (tester) async {
      await pumpAt(tester, const Size(844, 390));
      expect(find.byKey(const Key('login_wide_panel')), findsNothing);
      await tester.ensureVisible(find.text('Kích hoạt tài khoản'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final rect = tester.getRect(find.text('Kích hoạt tài khoản'));
      expect(rect.bottom, lessThanOrEqualTo(390));
    });

    testWidgets('resizing 900 → 700 → 900 keeps typed text and password visibility', (
      tester,
    ) async {
      await pumpAt(tester, const Size(900, 800));
      await tester.enterText(find.byType(TextField).at(0), 'lan@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret-1');
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      EditableText password() => tester.widget<EditableText>(
        find.byType(EditableText).at(1),
      );
      expect(password().obscureText, isFalse);

      for (final size in const [Size(700, 800), Size(900, 800)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.text('lan@example.com'), findsOneWidget);
        expect(find.text('secret-1'), findsOneWidget);
        expect(password().obscureText, isFalse);
      }
    });

    testWidgets('wide: Tab order email, password, forgot, submit', (tester) async {
      await pumpAt(tester, const Size(1280, 800));
      Finder editable(int i) => find.byType(EditableText).at(i);
      bool focusIn(Finder f) {
        final focus = FocusManager.instance.primaryFocus;
        if (focus == null) return false;
        return find
            .descendant(of: f, matching: find.byWidgetPredicate((w) => true))
            .evaluate()
            .any((e) => e == focus.context || _isAncestor(e, focus.context));
      }

      final stops = <String, Finder>{
        'email': editable(0),
        'password': editable(1),
        'forgot': find.widgetWithText(VButton, 'Quên mật khẩu?'),
        'submit': find.widgetWithText(VButton, 'Đăng nhập'),
      };
      final visited = <String>[];
      void record() {
        for (final entry in stops.entries) {
          if (focusIn(entry.value) && !visited.contains(entry.key)) {
            visited.add(entry.key);
          }
        }
      }

      await tester.tap(editable(0));
      await tester.pump();
      record();
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        record();
      }
      expect(visited, ['email', 'password', 'forgot', 'submit']);
    });

    for (final size in const [
      Size(840, 480),
      Size(860, 600),
      Size(1280, 500),
      Size(1280, 600),
    ]) {
      testWidgets('wide ${size.width}x${size.height}: banners scroll, never overflow', (
        tester,
      ) async {
        Future<void> expectReachable(String reason) async {
          expect(tester.takeException(), isNull, reason: reason);
          final last = find.text('Kích hoạt tài khoản');
          await tester.ensureVisible(last);
          await tester.pumpAndSettle();
          expect(
            tester.getRect(last).bottom,
            lessThanOrEqualTo(size.height),
            reason: reason,
          );
        }

        await pumpAt(tester, size, organizationName: 'Công ty ' * 10, showSuccessBanner: true);
        await expectReachable('joined');
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpAt(
          tester,
          size,
          organizationName: 'Thú y An Phát',
          showSuccessBanner: true,
          passwordResetSuccess: true,
        );
        await expectReachable('joined + reset');
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpAt(
          tester,
          size,
          auth: ScriptedAuthRepository(
            signInError: const AppException('NETWORK_ERROR'),
          ),
        );
        await tester.enterText(find.byType(TextField).at(0), 'lan@example.com');
        await tester.enterText(find.byType(TextField).at(1), 'secret');
        final submit = find.widgetWithText(VButton, 'Đăng nhập');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.text('Đăng nhập thất bại'), findsOneWidget);
        await expectReachable('network');
      });
    }

    for (final size in const [Size(840, 800), Size(1280, 800)]) {
      testWidgets('wide ${size.width} at text scale 2.0 does not overflow or clip', (
        tester,
      ) async {
        await pumpAt(tester, size, textScale: 2);
        expect(tester.takeException(), isNull);
        final label = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text('Mật khẩu'),
            matching: find.byType(RichText),
          ),
        );
        expect(
          label.size.height,
          greaterThanOrEqualTo(label.getMaxIntrinsicHeight(label.size.width)),
        );
      });
    }

    testWidgets('resizing does not commit the autofill context', (tester) async {
      await pumpAt(tester, const Size(900, 800));
      await tester.enterText(find.byType(TextField).at(1), 'nua-mat-khau');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.textInput,
          null,
        ),
      );
      for (final size in const [Size(700, 800), Size(860, 800), Size(1000, 800)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
      }
      expect(calls, isNot(contains('TextInput.finishAutofillContext')));
    });

    testWidgets('375x667 without a home bar keeps 16 under the footer', (
      tester,
    ) async {
      await pumpAt(tester, const Size(375, 667));
      final footer = find.textContaining('Phiên bản Mobile');
      await tester.ensureVisible(footer);
      await tester.pumpAndSettle();
      expect(tester.getRect(footer).bottom, lessThanOrEqualTo(667 - 16));
    });

    testWidgets('320 at text scale 2.0 does not overflow, long org name banner', (
      tester,
    ) async {
      await pumpAt(
        tester,
        const Size(320, 568),
        organizationName: 'Công ty ' * 10,
        showSuccessBanner: true,
        passwordResetSuccess: true,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Kích hoạt tài khoản'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('hành vi giữ nguyên khi đổi bố cục', () {
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

    testWidgets('typing clears email error', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.text('Đăng nhập').last);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'a');
      await tester.pump();
      expect(find.text('Vui lòng nhập email'), findsNothing);
    });

    testWidgets('typing clears the failure banner', (tester) async {
      await pumpLogin(
        tester,
        auth: ScriptedAuthRepository(
          signInError: const AppException('NETWORK_ERROR'),
        ),
      );
      await tester.enterText(find.byType(TextField).at(0), 'lan@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.text('Đăng nhập').last);
      await tester.pumpAndSettle();
      expect(find.byType(VBanner), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'lan2@example.com');
      await tester.pump();
      expect(find.byType(VBanner), findsNothing);
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

bool _isAncestor(Element ancestor, BuildContext? descendant) {
  if (descendant == null) return false;
  var found = false;
  descendant.visitAncestorElements((e) {
    if (e == ancestor) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}
