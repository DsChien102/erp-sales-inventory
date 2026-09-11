import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/testing.dart';

void main() {
  testWidgets('OrganizationRoleDetailPage renders role summary and permission groups (TA-D-02)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleRole = FakeRolesData.sampleRoles[1]; // Nhân viên bán hàng

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationRoleDetailPage(role: sampleRole),
      ),
    );
    await tester.pumpAndSettle();

    // Summary Card
    expect(find.text('Chi tiết vai trò'), findsOneWidget);
    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Bán hàng và chăm sóc khách hàng'), findsOneWidget);
    expect(find.text('14 quyền'), findsOneWidget);
    expect(find.text('Vai trò hệ thống · Chỉ đọc'), findsOneWidget);

    // Permission Groups
    expect(find.text('Bán hàng'), findsOneWidget);
    expect(find.text('Tạo và sửa đơn hàng'), findsOneWidget);
    expect(find.text('Tạo giao dịch trong cửa hàng'), findsOneWidget);
    expect(find.text('Thu tiền'), findsOneWidget);
    expect(find.text('Ghi nhận thanh toán được phép'), findsOneWidget);
    expect(find.text('Đổi trả hàng'), findsOneWidget);
    expect(find.text('Tiếp nhận đổi trả theo chính sách'), findsOneWidget);

    expect(find.text('Khách hàng & sản phẩm'), findsOneWidget);
    expect(find.text('Xem và cập nhật khách hàng'), findsOneWidget);
    expect(find.text('Quản lý thông tin liên hệ'), findsOneWidget);
    expect(find.text('Xem giá và tồn kho'), findsOneWidget);
    expect(find.text('Tra cứu thông tin phục vụ bán hàng'), findsOneWidget);
  });
}
