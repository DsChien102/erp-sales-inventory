import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:admin/features/iam/presentation.dart';

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
}
