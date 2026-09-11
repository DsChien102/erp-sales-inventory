import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/testing.dart';

void main() {
  testWidgets('OrganizationRolesPage renders system roles list (TA-D-01)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationRolesPage(
          initialRoles: FakeRolesData.sampleRoles,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Vai trò'), findsOneWidget);
    expect(find.text('4 vai trò hệ thống'), findsOneWidget);
    expect(find.text('Vai trò hệ thống'), findsOneWidget);
    expect(
      find.text('Vai trò vận hành không thay đổi tư cách Chủ sở hữu.'),
      findsOneWidget,
    );

    // Verify 4 roles list
    expect(find.text('Chủ cửa hàng'), findsOneWidget);
    expect(find.text('Quản lý toàn bộ cửa hàng · 38 quyền'), findsOneWidget);
    expect(find.text('Đang dùng'), findsOneWidget);

    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Bán hàng và chăm sóc khách hàng · 14 quyền'), findsOneWidget);

    expect(find.text('Kế toán'), findsOneWidget);
    expect(find.text('Công nợ, hóa đơn và báo cáo · 18 quyền'), findsOneWidget);

    expect(find.text('Thủ kho'), findsOneWidget);
    expect(find.text('Nhập xuất, tồn kho và kiểm kê · 12 quyền'), findsOneWidget);
  });

  testWidgets('OrganizationRolesPage opens detail page when tapping a role item', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationRolesPage(
          initialRoles: FakeRolesData.sampleRoles,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Nhân viên bán hàng'
    await tester.tap(find.text('Nhân viên bán hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết vai trò'), findsOneWidget);
    expect(find.text('14 quyền'), findsOneWidget);
    expect(find.text('Bán hàng'), findsOneWidget);
    expect(find.text('Khách hàng & sản phẩm'), findsOneWidget);
  });

  testWidgets('OrganizationRolesPage renders error state TA-S-02 when hasError is true', (
    WidgetTester tester,
  ) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationRolesPage(
          initialRoles: FakeRolesData.sampleRoles,
          hasError: true,
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được'), findsOneWidget);
    expect(find.text('Không thể tải danh sách vai trò'), findsOneWidget);
    expect(
      find.text('Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.'),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);

    // Tap 'Thử lại'
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(retried, isTrue);
    expect(find.text('4 vai trò hệ thống'), findsOneWidget);
  });
}
