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
    expect(find.text('Thử từ khóa khác.'), findsOneWidget);
    expect(find.text('Xóa tìm kiếm'), findsOneWidget);

    await tester.tap(find.text('Xóa tìm kiếm'));
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

    expect(find.text('Không thể tải danh sách tổ chức'), findsOneWidget);
    expect(
      find.text(
          'Kiểm tra kết nối mạng và thử lại. Dữ liệu cũ không được hiển thị khi quyền truy cập có thể đã thay đổi.'),
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

    expect(find.text('Bạn không có quyền quản lý'), findsOneWidget);
    expect(
      find.text(
          'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.'),
      findsOneWidget,
    );
    expect(find.text('Quay lại'), findsOneWidget);

    await tester.tap(find.text('Quay lại'));
    expect(actionCalled, isTrue);
  });
}
