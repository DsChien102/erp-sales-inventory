import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/src/organizations/models/organization_ui_model.dart';
import 'package:vet45_iam_presentation/src/organizations/views/organization_change_owner_page.dart';
import 'package:vet45_iam_presentation/src/organizations/widgets/organization_change_owner_confirmation_bottom_sheet.dart';

void main() {
  const sampleOrg = OrganizationUiModel(
    id: 'org-1',
    name: 'Mậu Hiền',
    code: 'TEN-000142',
    status: OrganizationStatus.active,
  );

  testWidgets('OrganizationChangeOwnerPage renders member list and search bar',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationChangeOwnerPage(organization: sampleOrg),
      ),
    );

    expect(find.text('Thay đổi chủ sở hữu'), findsOneWidget);
    expect(find.text('Chọn thành viên đang hoạt động'), findsOneWidget);
    expect(find.text('Trần Thị Hoa'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
    expect(find.text('Phạm Ngọc Mai'), findsOneWidget);
  });

  testWidgets(
      'Tapping member card updates radio selection and clicking Tiếp tục opens confirmation sheet',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationChangeOwnerPage(organization: sampleOrg),
      ),
    );

    // Tap on second member (Nguyễn Văn Minh)
    await tester.tap(find.text('Nguyễn Văn Minh'));
    await tester.pumpAndSettle();

    // Click Tiếp tục
    await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    expect(
        find.byType(OrganizationChangeOwnerConfirmationBottomSheet), findsOneWidget);
    expect(find.text('Chuyển quyền sở hữu cho Nguyễn Văn Minh?'), findsOneWidget);
    expect(find.text('Chuyển quyền'), findsOneWidget);
  });
}
