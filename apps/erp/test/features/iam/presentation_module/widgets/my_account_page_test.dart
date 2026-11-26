import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/models/sign_out_result.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/presentation/shared/detail_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../auth/support/scripted_auth.dart';
import '../../../../core/session/fake_session_repository.dart';
import '../../support/scripted_iam_repositories.dart';

void main() {
  testWidgets('wgt_e06_u01_fr01_01: MyAccountPage (TA-D-01) renders header, account summary and info rows',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MyAccountPage(data: MyAccountUiModel.sample),
      ),
    );

    // Title
    expect(find.text('Tài khoản của tôi'), findsOneWidget);

    // Card 1 — Identity summary
    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
    expect(find.text('Tài khoản cá nhân'), findsOneWidget);

    // Card 2 — Personal information
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
    expect(find.text('Họ và tên đệm'), findsOneWidget);
    expect(find.text('Nguyễn Văn'), findsOneWidget);

    expect(find.text('Tên'), findsOneWidget);
    expect(find.text('Minh'), findsOneWidget);

    expect(find.text('Email đăng nhập'), findsOneWidget);
    expect(find.text('minh@gmail.com'), findsOneWidget);

    expect(find.text('Trạng thái email'), findsOneWidget);
    expect(find.text('Đã xác minh'), findsOneWidget);

    expect(find.text('Số điện thoại'), findsOneWidget);
    expect(find.text('0901 234 567'), findsOneWidget);

    expect(find.text('Thao tác'), findsNothing);
    expect(find.text('Chỉnh sửa thông tin cá nhân'), findsOneWidget);
    expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
  });

  testWidgets('owner badge shows when isOwner is true', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MyAccountPage(
          data: MyAccountUiModel(
            firstName: 'Minh',
            lastName: 'Nguyễn Văn',
            email: 'minh@gmail.com',
            emailStatus: 'Đã xác minh',
            phoneNumber: '0901 234 567',
            isOwner: true,
          ),
        ),
      ),
    );

    expect(find.text('Chủ sở hữu'), findsOneWidget);
  });

  testWidgets('owner badge hidden when isOwner is false', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MyAccountPage(data: MyAccountUiModel.sample),
      ),
    );

    expect(find.text('Chủ sở hữu'), findsNothing);
  });

  testWidgets('owner badge still shows for owner when sample models tenant block UX', (
    tester,
  ) async {
    // Account page is personal — owner badge does not depend on current tenant.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MyAccountPage(
          data: MyAccountUiModel(
            firstName: 'Lan',
            lastName: 'Lê Thị',
            email: 'lan@gmail.com',
            emailStatus: 'Đã xác minh',
            phoneNumber: '',
            isOwner: true,
          ),
        ),
      ),
    );

    expect(find.text('Chủ sở hữu'), findsOneWidget);
    expect(find.text('Tài khoản cá nhân'), findsOneWidget);
  });

  testWidgets('successful password reset signs out and opens the login banner', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = loginSession();
    addTearDown(session.close);
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, state) => MyAccountPage(
            data: MyAccountUiModel.sample,
            session: session,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return LoginPage(
              auth: ScriptedAuthRepository(),
              session: session,
              passwordResetSuccess: extra?['passwordResetSuccess'] as bool? ?? false,
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: VTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    final passwordFields = find.byType(TextField);
    await tester.enterText(passwordFields.at(0), 'Password123!');
    await tester.enterText(passwordFields.at(1), 'Password123!');
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Đặt lại mật khẩu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(session.state.authStatus, AuthStatus.signedOut);
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('Cập nhật mật khẩu thành công'), findsOneWidget);
    expect(find.text('Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.'), findsOneWidget);
  });

  group('T0 behavior preservation at 390x844', () {
    Future<void> openActions(WidgetTester tester) async {}

    testWidgets('load error retries', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = ScriptedAccountRepository()
        ..getError = const AppException(AppErrorCode.network);
      final session = loginSession();
      addTearDown(session.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: MyAccountPage(accountRepository: repo, session: session),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tải được hồ sơ'), findsOneWidget);
      expect(find.widgetWithText(VButton, 'Thử lại'), findsOneWidget);

      repo.getError = null;
      await tester.tap(find.widgetWithText(VButton, 'Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Le Lan'), findsOneWidget);
    });

    testWidgets('edit saves then toast', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const MyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      await openActions(tester);
      await tester.tap(find.text('Chỉnh sửa thông tin cá nhân'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'Hải');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn Hải'), findsOneWidget);
      expect(find.text('Đã cập nhật thông tin cá nhân'), findsOneWidget);
    });

    testWidgets('reset password signs out', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = loginSession();
      addTearDown(session.close);
      final router = GoRouter(
        initialLocation: '/account',
        routes: [
          GoRoute(
            path: '/account',
            builder: (context, state) => MyAccountPage(
              data: MyAccountUiModel.sample,
              session: session,
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return LoginPage(
                auth: ScriptedAuthRepository(),
                session: session,
                passwordResetSuccess: extra?['passwordResetSuccess'] as bool? ?? false,
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await openActions(tester);
      await tester.tap(find.text('Đặt lại mật khẩu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(0), 'Password123!');
      await tester.enterText(passwordFields.at(1), 'Password123!');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Đặt lại mật khẩu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(session.state.authStatus, AuthStatus.signedOut);
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(find.text('Cập nhật mật khẩu thành công'), findsOneWidget);
    });

    testWidgets('signing out twice in a row calls signOut once', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var calls = 0;
      final gate = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: MyAccountPage(
            data: MyAccountUiModel.sample,
            onLogout: () async {
              calls++;
              await gate.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openActions(tester);
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Đăng xuất').last);
      await tester.pump();

      await openActions(tester);
      await tester.tap(find.text('Đăng xuất').first);
      await tester.pump();

      expect(calls, 1);
      gate.complete();
      await tester.pumpAndSettle();
    });

    Future<void> completeReset(WidgetTester tester) async {
      await openActions(tester);
      await tester.tap(find.text('Đặt lại mật khẩu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(0), 'Password123!');
      await tester.enterText(passwordFields.at(1), 'Password123!');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Đặt lại mật khẩu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('failed sign-out after password reset shows a toast and stays', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = loginSession();
      addTearDown(session.close);
      final router = GoRouter(
        initialLocation: '/account',
        routes: [
          GoRoute(
            path: '/account',
            builder: (context, state) => MyAccountPage(
              data: MyAccountUiModel.sample,
              session: session,
              onResetSignOut: () async =>
                  const SignOutResult(localCleared: false, remoteSucceeded: false),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await completeReset(tester);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/account');
      expect(find.text('Không thể đóng phiên trên máy.'), findsOneWidget);
    });

    testWidgets('remote failure still goes to login with the banner', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = _MockGoTrueClient();
      when(() => auth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
      when(() => auth.currentUser).thenReturn(null);
      when(() => auth.currentSession).thenReturn(null);
      when(() => auth.signOut()).thenThrow(Exception('remote sign-out failed'));
      final session = SessionController(
        repository: FakeSessionRepository(),
        auth: auth,
        store: SessionStore()..applyAuthenticatedUser('u1'),
        initialState: const SessionState(
          authStatus: AuthStatus.signedIn,
          userId: 'u1',
        ),
      );
      addTearDown(session.close);
      final router = GoRouter(
        initialLocation: '/account',
        routes: [
          GoRoute(
            path: '/account',
            builder: (context, state) => MyAccountPage(
              data: MyAccountUiModel.sample,
              session: session,
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return LoginPage(
                auth: ScriptedAuthRepository(),
                session: session,
                passwordResetSuccess: extra?['passwordResetSuccess'] as bool? ?? false,
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await completeReset(tester);

      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(find.text('Cập nhật mật khẩu thành công'), findsOneWidget);
    });
  });

  group('10-8k MyAccountPage narrow & wide', () {
    testWidgets('390: rows and three actions in the page, no Thao tác, no bottom bar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const MyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MyAccountNarrow), findsOneWidget);
      expect(find.byType(MyAccountWide), findsNothing);
      expect(find.text('Thao tác'), findsNothing);
      expect(find.text('Chỉnh sửa thông tin cá nhân'), findsOneWidget);
      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
      expect(find.text('NM'), findsOneWidget);
      final scaffold = tester.widget<VPageScaffold>(find.byType(VPageScaffold));
      expect(scaffold.bottomBar, isNull);
    });

    testWidgets('1280: profile card, pencil, security section', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const MyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MyAccountWide), findsOneWidget);
      expect(find.byType(MyAccountNarrow), findsNothing);
      expect(find.byTooltip('Chỉnh sửa thông tin cá nhân'), findsOneWidget);
      expect(find.text('Bảo mật'), findsOneWidget);
      expect(find.widgetWithText(VButton, 'Đặt lại mật khẩu'), findsOneWidget);
      expect(find.widgetWithText(VButton, 'Đăng xuất'), findsOneWidget);
    });

    testWidgets('1280: empty value is muted, rows spaced like prototype, initials 24', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const MyAccountPage(
            data: MyAccountUiModel(
              firstName: 'Minh',
              lastName: 'Nguyễn Văn',
              email: 'minh@gmail.com',
              emailStatus: 'Đã xác minh',
              phoneNumber: '',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MyAccountWide));
      final colors = context.vColors;
      final empty = tester.widget<Text>(
        find.descendant(of: find.byType(DetailRow), matching: find.text('(chưa có)')),
      );
      expect(empty.style?.color, colors.textMuted);
      expect(empty.style?.fontWeight, FontWeight.w500);
      final label = tester.widget<Text>(
        find.descendant(of: find.byType(DetailRow), matching: find.text('Số điện thoại')),
      );
      expect(label.style?.color, colors.textSecondary);

      // `.t1-acrow`: đệm dọc 8 mỗi dòng + gap 4 → hai dòng cách nhau 22 + 20.
      final first = tester.getTopLeft(find.text('Họ và tên đệm')).dy;
      final second = tester.getTopLeft(find.text('Tên').last).dy;
      expect(second - first, greaterThanOrEqualTo(40));

      final initials = tester.widget<Text>(find.text('NM'));
      expect(initials.style?.fontSize, 24);
    });

    testWidgets('870 stacks the two columns', (tester) async {
      tester.view.physicalSize = const Size(870, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const MyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MyAccountWide), findsOneWidget);
      final profileTop = tester.getTopLeft(find.byType(FlowCard)).dy;
      final infoTop = tester.getTopLeft(find.text('Thông tin cá nhân')).dy;
      expect(infoTop, greaterThan(profileTop + 100));
    });

    testWidgets('390 and 1280: Đăng xuất asks first, confirming signs out once', (
      tester,
    ) async {
      for (final size in const [Size(390, 844), Size(1280, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        var calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: MyAccountPage(
              data: MyAccountUiModel.sample,
              onLogout: () async {
                calls++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Đăng xuất'));
        await tester.pumpAndSettle();

        expect(find.text('Đăng xuất khỏi Mosaic Retail?'), findsOneWidget);
        expect(
          find.text('Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng ứng dụng.'),
          findsOneWidget,
        );
        expect(calls, 0);

        await tester.tap(find.widgetWithText(VButton, 'Đăng xuất').last);
        await tester.pumpAndSettle();
        expect(calls, 1);
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('Quay lại, Esc and tapping outside do not sign out', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: MyAccountPage(
            data: MyAccountUiModel.sample,
            onLogout: () async {
              calls++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quay lại
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất khỏi Mosaic Retail?'), findsNothing);
      expect(calls, 0);

      // Esc
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất khỏi Mosaic Retail?'), findsNothing);
      expect(calls, 0);

      // Tap outside
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất khỏi Mosaic Retail?'), findsNothing);
      expect(calls, 0);
    });

    testWidgets('1280: the confirmation is a dialog with a close button', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const MyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.byTooltip('Đóng'), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất khỏi Mosaic Retail?'), findsNothing);
    });

    testWidgets('back is hidden at 1024 and above in every state', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1023 pushed from /more: has back
      tester.view.physicalSize = const Size(1023, 800);
      final router1023 = GoRouter(
        initialLocation: '/more',
        routes: [
          GoRoute(
            path: '/more',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/more/my-account'),
                child: const Text('Go'),
              ),
            ),
            routes: [
              GoRoute(
                path: 'my-account',
                builder: (context, state) => const MyAccountPage(
                  data: MyAccountUiModel.sample,
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router1023.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router1023),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quay lại'), findsOneWidget);

      // 1024: no back in data, loading, error
      tester.view.physicalSize = const Size(1024, 800);
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const MyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quay lại'), findsNothing);

      final repoErr = ScriptedAccountRepository()
        ..getError = const AppException(AppErrorCode.network);
      final session = loginSession();
      addTearDown(session.close);
      final cubitErr = MyAccountCubit(accountRepository: repoErr, session: session);
      addTearDown(cubitErr.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: MyAccountPage(cubit: cubitErr),
        ),
      );
      await tester.pump();
      expect(find.byTooltip('Quay lại'), findsNothing);

      await cubitErr.load();
      await tester.pump();
      expect(find.byTooltip('Quay lại'), findsNothing);
    });

    testWidgets('1280 opened by go: edit and reset still return here', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const MyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Chỉnh sửa thông tin cá nhân'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh sửa thông tin'), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Tài khoản của tôi'), findsOneWidget);

      await tester.tap(find.widgetWithText(VButton, 'Đặt lại mật khẩu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Đặt lại mật khẩu'), findsWidgets);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Tài khoản của tôi'), findsOneWidget);
    });

    testWidgets('320 at text scale 2.0 and 840 with long name and email do not overflow', (
      tester,
    ) async {
      const longData = MyAccountUiModel(
        firstName: 'Thị Minh Phương Anh',
        lastName: 'Nguyễn Trần Lê Hoàng Vũ Phạm',
        email: 'nguyen.tran.le.hoang.vu.pham.minh.phuong.anh@congtytnhh.com.vn',
        emailStatus: 'Đã xác minh',
        phoneNumber: '0912 345 678',
        isOwner: true,
      );

      for (final cfg in const [
        (size: Size(320, 844), scale: 2.0),
        (size: Size(840, 800), scale: 1.0),
      ]) {
        tester.view.physicalSize = cfg.size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(cfg.scale)),
            child: MaterialApp(
              theme: VTheme.lightTheme,
              home: const MyAccountPage(data: longData),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('labeled tap targets', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const MyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}

class _MockGoTrueClient extends Mock implements GoTrueClient {}
