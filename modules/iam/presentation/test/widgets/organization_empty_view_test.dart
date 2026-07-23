import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/src/organizations/widgets/organization_empty_view.dart';

void main() {
  testWidgets('OrganizationEmptyView renders noOrganizations state correctly',
      (tester) async {
    bool actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationEmptyView(
            type: OrganizationEmptyStateType.noOrganizations,
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Chưa có tổ chức'), findsOneWidget);
    expect(
        find.text(
            'Khởi tạo tổ chức đầu tiên để bắt đầu quản lý tổ chức trên nền tảng.'),
        findsOneWidget);
    expect(find.text('Khởi tạo tổ chức'), findsOneWidget);

    await tester.tap(find.text('Khởi tạo tổ chức'));
    expect(actionCalled, isTrue);
  });

  testWidgets('OrganizationEmptyView renders noResults state correctly',
      (tester) async {
    bool actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationEmptyView(
            type: OrganizationEmptyStateType.noResults,
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Không tìm thấy tổ chức'), findsOneWidget);
    expect(
        find.text('Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.'),
        findsOneWidget);
    expect(find.text('Xóa bộ lọc'), findsOneWidget);

    await tester.tap(find.text('Xóa bộ lọc'));
    expect(actionCalled, isTrue);
  });

  testWidgets('OrganizationEmptyView renders loadError state correctly',
      (tester) async {
    bool actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationEmptyView(
            type: OrganizationEmptyStateType.loadError,
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Không thể tải danh sách'), findsOneWidget);
    expect(
        find.text('Đã xảy ra lỗi khi tải danh sách tổ chức. Vui lòng thử lại.'),
        findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    expect(actionCalled, isTrue);
  });

  testWidgets('OrganizationEmptyView renders unauthorized state correctly',
      (tester) async {
    bool actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationEmptyView(
            type: OrganizationEmptyStateType.unauthorized,
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Bạn không có quyền quản lý'), findsOneWidget);
    expect(
        find.text(
            'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.'),
        findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);

    await tester.tap(find.text('Quay lại'));
    expect(actionCalled, isTrue);
  });
}
