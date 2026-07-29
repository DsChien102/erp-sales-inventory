import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/src/organizations/widgets/organization_empty_view.dart';

void main() {
  testWidgets(
      'OrganizationEmptyView renders noAuthorizedOrganizations state correctly (Card 2)',
      (tester) async {
    bool actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationEmptyView(
            type: OrganizationEmptyStateType.noAuthorizedOrganizations,
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Chưa có tổ chức được cấp quyền'), findsOneWidget);
    expect(
      find.text(
          'Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.'),
      findsOneWidget,
    );
    expect(find.text('Kiểm tra lại'), findsOneWidget);

    await tester.tap(find.text('Kiểm tra lại'));
    expect(actionCalled, isTrue);
  });

  testWidgets(
      'OrganizationEmptyView renders inaccessible state correctly (Card 1)',
      (tester) async {
    bool actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationEmptyView(
            type: OrganizationEmptyStateType.inaccessible,
            suspendedOrgName: 'ASC Commerce',
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Tổ chức không thể truy cập'), findsOneWidget);
    expect(
      find.text(
          'ASC Commerce đang tạm ngừng. Bạn không thể truy cập dữ liệu của tổ chức này.'),
      findsOneWidget,
    );
    expect(find.text('Chọn tổ chức khác'), findsOneWidget);

    await tester.tap(find.text('Chọn tổ chức khác'));
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
      findsOneWidget,
    );
    expect(find.text('Xóa bộ lọc'), findsOneWidget);

    await tester.tap(find.text('Xóa bộ lọc'));
    expect(actionCalled, isTrue);
  });

  testWidgets(
      'OrganizationEmptyView renders loadError state correctly (Card 3)',
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
      findsOneWidget,
    );
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

    expect(find.text('Không có quyền xem tổ chức'), findsOneWidget);
    expect(
      find.text(
          'Liên hệ chủ cửa hàng để được cấp quyền quản lý tổ chức nền tảng.'),
      findsOneWidget,
    );
    expect(find.text('Quay lại'), findsOneWidget);

    await tester.tap(find.text('Quay lại'));
    expect(actionCalled, isTrue);
  });

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
      findsOneWidget,
    );
    expect(find.text('Khởi tạo tổ chức'), findsOneWidget);

    await tester.tap(find.text('Khởi tạo tổ chức'));
    expect(actionCalled, isTrue);
  });
}
