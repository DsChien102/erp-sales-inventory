import 'package:erp/core/session/session_state.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../auth/support/scripted_auth.dart';

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

    // Bottom Action button
    expect(find.text('Thao tác'), findsOneWidget);
  });

  testWidgets('Tapping Thao tác opens action bottom sheet',
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

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Thao tác tài khoản'), findsOneWidget);
    expect(find.text('Chỉnh sửa thông tin cá nhân'), findsOneWidget);
    expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
  });

  testWidgets(
      'Tapping Đăng xuất option shows logout confirmation bottom sheet and triggers onLogout callback',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var logoutCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MyAccountPage(
          data: MyAccountUiModel.sample,
          onLogout: () async {
            logoutCalled = true;
          },
        ),
      ),
    );

    // Open actions bottom sheet
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    // Tap logout option
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    // Verify logout confirmation bottom sheet is displayed
    expect(find.text('Đăng xuất khỏi VET45?'), findsOneWidget);
    expect(
      find.text('Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng ứng dụng.'),
      findsOneWidget,
    );

    // Verify both buttons are present
    final quayLaiButton = find.widgetWithText(VButton, 'Quay lại');
    final dangXuatButton = find.widgetWithText(VButton, 'Đăng xuất');
    expect(quayLaiButton, findsOneWidget);
    expect(dangXuatButton, findsOneWidget);

    // Tap Đăng xuất button to trigger onLogout callback
    await tester.tap(dangXuatButton);
    await tester.pumpAndSettle();

    expect(logoutCalled, isTrue);
  });

  testWidgets(
      'Tapping Quay lại in logout confirmation closes the bottom sheet',
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

    // Open actions bottom sheet
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    // Tap logout option
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    // Verify confirmation bottom sheet
    expect(find.text('Đăng xuất khỏi VET45?'), findsOneWidget);

    // Tap Quay lại
    await tester.tap(find.widgetWithText(VButton, 'Quay lại'));
    await tester.pumpAndSettle();

    // Confirmation bottom sheet should be dismissed
    expect(find.text('Đăng xuất khỏi VET45?'), findsNothing);
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

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
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
}
