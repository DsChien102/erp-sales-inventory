import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/session/session_store.dart';
import '../../iam/support/fake_iam_backend.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../../../core/session/fake_session_repository.dart';
import '../../iam/support/scripted_iam_repositories.dart';

/// e2e_e06_u01/u02/u03/u04 — ERP My Account via FakeIamBackend (Group E / S14).
void main() {
  final getIt = GetIt.instance;
  final sessions = <SessionController>[];

  var signOutCalls = 0;

  setUp(() async {
    await getIt.reset();
    signOutCalls = 0;
  });

  tearDown(() async {
    for (final controller in sessions) {
      await controller.close();
    }
    sessions.clear();
    await getIt.reset();
  });

  void registerModule(FakeIamBackend module) {
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<FakeIamBackend>(module);
  }

  SessionController sessionFor({
    bool remoteFails = false,
    FakeIamScenario scenario = FakeIamScenario.usersSearchOk,
  }) {
    final auth = _MockAuth();
    when(() => auth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.currentSession).thenReturn(null);
    when(() => auth.signOut()).thenAnswer((_) async {
      signOutCalls += 1;
      if (remoteFails) throw Exception('remote sign-out failed');
    });
    final controller = SessionController(
      repository: FakeSessionRepository(scenario: scenario),
      auth: auth,
      store: SessionStore()..applyAuthenticatedUser('user-1'),
    );
    sessions.add(controller);
    return controller;
  }

  Widget wrap(
    FakeIamBackend module, {
    bool warnRemoteSignOut = false,
    ScriptedAccountRepository? account,
    RecordingAuthRepository? auth,
  }) {
    final accountRepository = account ?? ScriptedAccountRepository();
    final authRepository = auth ?? RecordingAuthRepository();
    final session = sessionFor(
      remoteFails: warnRemoteSignOut,
      scenario: module.scenario,
    );
    final router = GoRouter(
      initialLocation: '/more/my-account',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Login')),
          ),
        ),
        GoRoute(
          path: '/more/my-account',
          builder: (context, state) => MyAccountPage(
            accountRepository: accountRepository,
            authRepository: authRepository,
            session: session,
            onLogout: () async {
              final result = await session.signOut();
              if (!result.localCleared) return;
              if (warnRemoteSignOut && !result.remoteSucceeded && context.mounted) {
                VToast.show(
                  context,
                  title: 'Cảnh báo',
                  message: 'Phiên trên máy đã đóng; máy chủ chưa xác nhận đăng xuất',
                  type: VToastType.warning,
                );
              }
              if (context.mounted) context.go('/login');
            },
          ),
        ),
        GoRoute(
          path: '/more/my-account/edit',
          builder: (context, state) => EditMyAccountPage(
            accountRepository: accountRepository,
          ),
        ),
        GoRoute(
          path: '/more/my-account/reset-password',
          builder: (context, state) => ResetPasswordPage(
            authRepository: authRepository,
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('e2e_e06_u01_fr01_01: load my profile', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.myAccountOk);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản của tôi'), findsOneWidget);
    expect(find.text('Le Lan'), findsOneWidget);
    expect(find.text('lan@gmail.com'), findsOneWidget);
  });

  testWidgets('e2e_e06_u02_fr01_01: edit profile save', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.myAccountUpdateOk);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa thông tin cá nhân'));
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa thông tin'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Trần Văn');
    await tester.enterText(fields.at(1), 'A');
    await tester.pump();

    await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(find.text('Trần Văn A'), findsOneWidget);
  });

  testWidgets('e2e_e06_u03_fr01_01: password reset happy path', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.passwordResetCompleteOk);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.text('Đặt lại mật khẩu'), findsWidgets);

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, '123456');
    await tester.pump();
    final confirm = find.text('Xác nhận mã');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Tạo mật khẩu mới'), findsOneWidget);

    final passwordFields = find.byType(TextField);
    await tester.enterText(passwordFields.at(0), 'Password1!');
    await tester.enterText(passwordFields.at(1), 'Password1!');
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Đặt lại mật khẩu'));
    await tester.pumpAndSettle();

    expect(signOutCalls, 1);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('e2e_e06_u04_fr01_01: logout clears session', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.myAccountOk);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất khỏi VET45?'), findsOneWidget);
    await tester.tap(find.widgetWithText(VButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(signOutCalls, 1);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets(
    'e2e_e06_u04_fr01_02: remote sign-out failure still clears local and warns',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.signOutRemoteError);
      registerModule(module);

      await tester.pumpWidget(wrap(module, warnRemoteSignOut: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Đăng xuất'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(
        find.textContaining('máy chủ chưa xác nhận'),
        findsOneWidget,
      );
    },
  );
}

class _MockAuth extends Mock implements GoTrueClient {}
