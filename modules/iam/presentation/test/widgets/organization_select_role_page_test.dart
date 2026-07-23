import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/src/users/models/user_ui_model.dart';
import 'package:vet45_iam_presentation/src/users/views/organization_select_role_page.dart';

void main() {
  const sampleMember = MemberUiModel(
    id: 'mem-1',
    name: 'Nguyễn Văn Minh',
    email: 'minh@minhphat.vn',
    role: 'Nhân viên bán hàng',
    status: MemberStatus.active,
  );

  testWidgets('OrganizationSelectRolePage renders role options (TA-D-03)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationSelectRolePage(member: sampleMember),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chọn vai trò'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
    expect(find.text('Chọn vai trò mới'), findsOneWidget);

    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Kế toán'), findsOneWidget);
    expect(find.text('Thủ kho'), findsOneWidget);
    expect(find.text('Chủ cửa hàng'), findsOneWidget);

    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });
}
