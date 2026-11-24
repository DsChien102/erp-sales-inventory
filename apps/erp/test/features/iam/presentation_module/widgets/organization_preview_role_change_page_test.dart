import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/iam/presentation/users/models/user_ui_model.dart';
import 'package:erp/features/iam/presentation/users/views/organization_preview_role_change_page.dart';

void main() {
  const sampleMember = MemberUiModel(
    id: 'mem-1',
    name: 'Nguyễn Văn Minh',
    email: 'minh@minhphat.vn',
    role: 'Nhân viên bán hàng',
    status: MemberStatus.active,
  );

  testWidgets('OrganizationPreviewRoleChangePage renders preview sections (TA-D-04)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationPreviewRoleChangePage(
          member: sampleMember,
          newRole: 'Kế toán',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Xem trước thay đổi'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);

    expect(find.text('Thay đổi vai trò'), findsOneWidget);
    expect(find.text('Vai trò hiện tại'), findsOneWidget);
    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Vai trò mới'), findsOneWidget);
    expect(find.text('Kế toán'), findsOneWidget);

    expect(find.text('Quyền được thêm'), findsNothing);
    expect(find.text('Quyền bị gỡ'), findsNothing);
    expect(
      find.text('Vai trò là nhãn công việc; quyền nghiệp vụ của thành viên không thay đổi.'),
      findsOneWidget,
    );

    expect(find.text('Quay lại'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });
}
