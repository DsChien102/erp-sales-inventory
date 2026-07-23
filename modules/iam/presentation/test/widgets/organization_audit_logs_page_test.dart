import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets('OrganizationAuditLogsPage renders header, search bar, filter chips, and log list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationAuditLogsPage(),
      ),
    );

    // Verify title & header
    expect(find.text('Lịch sử quản trị'), findsOneWidget);
    expect(find.textContaining('hoạt động trong 30 ngày'), findsOneWidget);

    // Verify search bar hint
    expect(find.text('Tìm người thực hiện hoặc hoạt động'), findsOneWidget);

    // Verify Quick Filter category chips
    expect(find.text('Tất cả'), findsWidgets);
    expect(find.text('Thành viên'), findsWidgets);
    expect(find.text('Vai trò'), findsWidgets);
    expect(find.text('Tổ chức'), findsWidgets);

    // Verify Subtitle meta text
    expect(find.text('Thời gian: 30 ngày gần đây · Mới nhất trước'), findsOneWidget);

    // Verify items in the fake log list
    expect(find.text('Thay đổi vai trò thành viên'), findsOneWidget);
    expect(find.text('Cập nhật email liên hệ'), findsOneWidget);
    expect(find.text('Mời thành viên'), findsOneWidget);
    expect(find.text('Đã đồng bộ quyền hiệu lực'), findsOneWidget);
  });

  testWidgets('OrganizationAuditLogsPage filters list by quick category chip', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationAuditLogsPage(),
      ),
    );

    // Tap 'Vai trò' category chip
    await tester.tap(find.text('Vai trò').first);
    await tester.pumpAndSettle();

    // Verify filtered result contains 'Thay đổi vai trò thành viên' and does NOT contain 'Cập nhật email liên hệ'
    expect(find.text('Thay đổi vai trò thành viên'), findsOneWidget);
    expect(find.text('Cập nhật email liên hệ'), findsNothing);
  });

  testWidgets('OrganizationAuditLogsPage displays empty state on non-matching search', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationAuditLogsPage(),
      ),
    );

    // Enter search query
    await tester.enterText(find.byType(TextField), 'NonExistentActionKeywordsXYZ');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Không có hoạt động phù hợp'), findsOneWidget);
    expect(find.text('Xóa bộ lọc'), findsOneWidget);
  });

  testWidgets('OrganizationAuditLogsPage displays unauthorized empty state when isUnauthorized is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationAuditLogsPage(isUnauthorized: true),
      ),
    );

    expect(find.text('Bạn không có quyền xem lịch sử quản trị'), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
  });

  testWidgets('OrganizationAuditLogsPage displays load error state when hasError is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationAuditLogsPage(hasError: true),
      ),
    );

    expect(find.text('Không thể tải lịch sử quản trị'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
