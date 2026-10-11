import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/iam/presentation.dart';
import '../../support/iam_fixtures.dart';

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
    expect(find.text('Vai trò hệ thống · Chỉ đọc'), findsOneWidget);
    expect(find.textContaining('quyền'), findsNothing);
    expect(find.text('Chưa có thành viên đang giữ vai trò này.'), findsOneWidget);
  });
}
