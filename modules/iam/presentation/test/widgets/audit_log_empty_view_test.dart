import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/src/audit_logs/widgets/audit_log_empty_view.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  testWidgets('AuditLogEmptyView renders noAuditLogs state correctly',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      buildTestableWidget(
        AuditLogEmptyView(
          type: AuditLogEmptyStateType.noAuditLogs,
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Chưa có hoạt động quản trị'), findsOneWidget);
    expect(
      find.text(
          'Các thay đổi người dùng, vai trò và thiết lập sẽ được ghi lại tại đây.'),
      findsOneWidget,
    );
    expect(find.text('Tải lại'), findsOneWidget);

    await tester.tap(find.text('Tải lại'));
    expect(tapped, isTrue);
  });

  testWidgets('AuditLogEmptyView renders noResults state correctly',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      buildTestableWidget(
        AuditLogEmptyView(
          type: AuditLogEmptyStateType.noResults,
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Không có hoạt động phù hợp'), findsOneWidget);
    expect(
      find.text('Thử thay đổi từ khóa hoặc bộ lọc đang áp dụng.'),
      findsOneWidget,
    );
    expect(find.text('Xóa bộ lọc'), findsOneWidget);

    await tester.tap(find.text('Xóa bộ lọc'));
    expect(tapped, isTrue);
  });

  testWidgets('AuditLogEmptyView renders loadError state correctly',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      buildTestableWidget(
        AuditLogEmptyView(
          type: AuditLogEmptyStateType.loadError,
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Không thể tải lịch sử quản trị'), findsOneWidget);
    expect(
      find.text('Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    expect(tapped, isTrue);
  });

  testWidgets('AuditLogEmptyView renders unauthorized state correctly',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      buildTestableWidget(
        AuditLogEmptyView(
          type: AuditLogEmptyStateType.unauthorized,
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Bạn không có quyền xem lịch sử quản trị'), findsOneWidget);
    expect(
      find.text(
          'Liên hệ Chủ sở hữu hoặc người có quyền quản trị để được cấp quyền.'),
      findsOneWidget,
    );
    expect(find.text('Quay lại'), findsOneWidget);

    await tester.tap(find.text('Quay lại'));
    expect(tapped, isTrue);
  });
}
