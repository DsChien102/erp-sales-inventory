import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/audit/presentation/pages/audit_logs_page.dart';

void main() {
  testWidgets('AuditLogsPage renders search bar, filter chips, and log items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuditLogsPage(),
        ),
      ),
    );

    // Verify time info
    expect(find.text('Thời gian: 24 giờ gần đây  ·  Mới nhất trước'), findsOneWidget);

    // Verify filter chips
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Thành công'), findsOneWidget);
    expect(find.text('Bị chặn'), findsOneWidget);
    expect(find.text('Lỗi'), findsOneWidget);

    // Verify initial log items
    expect(find.text('Đã tạm ngừng tổ chức'), findsOneWidget);
    expect(find.text('Từ chối thao tác không đủ quyền'), findsOneWidget);
    expect(find.text('Khởi tạo tổ chức chưa hoàn tất'), findsOneWidget);
    expect(find.text('Làm mới chính sách quyền'), findsOneWidget);
  });

  testWidgets('AuditLogsPage filters logs when tapping status chips', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuditLogsPage(),
        ),
      ),
    );

    // Tap 'Bị chặn' chip
    await tester.tap(find.text('Bị chặn'));
    await tester.pumpAndSettle();

    // Verify only 'Bị chặn' item is shown
    expect(find.text('Từ chối thao tác không đủ quyền'), findsOneWidget);
    expect(find.text('Đã tạm ngừng tổ chức'), findsNothing);
  });

  testWidgets('AuditLogsPage opens AuditLogDetailPage on log item tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuditLogsPage(),
        ),
      ),
    );

    // Tap first log item
    await tester.tap(find.text('Đã tạm ngừng tổ chức'));
    await tester.pumpAndSettle();

    // Verify Detail Page PA-D-03 elements
    expect(find.text('Chi tiết hoạt động'), findsOneWidget);
    expect(find.text('Người thực hiện & ngữ cảnh'), findsOneWidget);
    expect(find.text('Đối tượng'), findsOneWidget);
    expect(find.text('Thông tin truy vết'), findsOneWidget);
    expect(find.text('Dữ liệu thay đổi'), findsOneWidget);
    expect(find.text('Tùng Nguyễn'), findsOneWidget);
    expect(find.text('VietVet Trading'), findsOneWidget);
  });
}
