import 'dart:async';

import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../receivable/presentation/receivable_test_harness.dart';
import '../support/scripted_auth.dart';

/// Chụp một màn công khai ở 390 (iPhone, thanh trạng thái 30, thanh Home 34) hoặc 1280.
/// Ảnh: `docs/refactor/plans/P10/img/10-8e/flutter-<name>-<width>.png`.
Future<void> captureAuth(
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
  await tester.pump(const Duration(milliseconds: 50));
  if (act != null) await act();
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(
      '${repoRoot()}/docs/refactor/plans/P10/img/10-8e/flutter-$name-$width.png',
    ),
  );
}

class _HangingSignIn extends ScriptedAuthRepository {
  final gate = Completer<void>();

  @override
  Future<String> signIn({required String email, required String password}) async {
    await gate.future;
    return super.signIn(email: email, password: password);
  }
}

void main() {
  setUpAll(loadInterFont);

  group('login', () {
    for (final width in const [390, 1280]) {
      Future<void> run(
        WidgetTester tester,
        String name, {
        ScriptedAuthRepository? auth,
        String? organizationName,
        bool joined = false,
        String? prefilledEmail,
        Future<void> Function(WidgetTester)? act,
        bool settle = true,
      }) async {
        final session = loginSession();
        addTearDown(session.close);
        await captureAuth(
          tester,
          width: width,
          name: name,
          page: LoginPage(
            auth: auth ?? ScriptedAuthRepository(),
            session: session,
            showSuccessBanner: joined,
            organizationName: organizationName,
            prefilledEmail: prefilledEmail,
          ),
          act: act == null
              ? null
              : () async {
                  await act(tester);
                  if (settle) await tester.pumpAndSettle();
                },
        );
      }

      Future<void> fill(WidgetTester tester) async {
        await tester.enterText(find.byType(TextField).at(0), 'lan@anphat.vn');
        await tester.enterText(find.byType(TextField).at(1), 'matkhau12');
      }

      Future<void> submit(WidgetTester tester) async {
        await tester.tap(find.widgetWithText(VButton, 'Đăng nhập'));
      }

      testWidgets('login__default $width', (tester) async {
        await run(tester, 'login__default');
      });
      testWidgets('login__wrong-credentials $width', (tester) async {
        await run(
          tester,
          'login__wrong-credentials',
          auth: ScriptedAuthRepository(
            signInError: const AppException(IamBlockedCodes.invalidCredentials),
          ),
          act: (t) async {
            await fill(t);
            await submit(t);
          },
        );
      });
      testWidgets('login__network $width', (tester) async {
        await run(
          tester,
          'login__network',
          auth: ScriptedAuthRepository(
            signInError: const AppException('NETWORK_ERROR'),
          ),
          act: (t) async {
            await fill(t);
            await submit(t);
          },
        );
      });
      testWidgets('login__joined $width', (tester) async {
        await run(
          tester,
          'login__joined',
          joined: true,
          organizationName: 'Thú y An Phát',
          prefilledEmail: 'minh@anphat.vn',
        );
      });
      testWidgets('login__submitting $width', (tester) async {
        final auth = _HangingSignIn();
        addTearDown(() => auth.gate.complete());
        await run(
          tester,
          'login__submitting',
          auth: auth,
          settle: false,
          act: (t) async {
            await fill(t);
            await submit(t);
            await t.pump(const Duration(milliseconds: 100));
          },
        );
      });
    }
  });
}
