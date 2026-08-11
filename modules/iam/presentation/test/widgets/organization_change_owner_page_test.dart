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
    ownerUserId: 'owner-01',
    members: [
      OrganizationMemberUiModel(
        id: 'owner-01',
        name: 'Lê Thị Lan',
        email: 'lan@minhphat.vn',
        role: 'Chủ cửa hàng',
        avatarInitials: 'LL',
        isOwner: true,
      ),
      OrganizationMemberUiModel(
        id: 'mem-01',
        name: 'Trần Thị Hoa',
        email: 'hoa@minhphat.vn',
        role: 'Kế toán',
        avatarInitials: 'TH',
      ),
      OrganizationMemberUiModel(
        id: 'mem-02',
        name: 'Nguyễn Văn Minh',
        email: 'minh@minhphat.vn',
        role: 'Nhân viên bán hàng',
        avatarInitials: 'NV',
      ),
    ],
  );

  const emptyOrg = OrganizationUiModel(
    id: 'org-empty',
    name: 'Tổ chức trống',
    code: 'TEN-EMPTY',
    status: OrganizationStatus.active,
  );

  testWidgets('OrganizationChangeOwnerPage renders provided members', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationChangeOwnerPage(organization: sampleOrg),
      ),
    );

    expect(find.text('Thay đổi chủ sở hữu'), findsOneWidget);
    expect(find.text('Chọn thành viên đang hoạt động'), findsOneWidget);
    expect(find.text('Trần Thị Hoa'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
    expect(find.text('Phạm Ngọc Mai'), findsNothing);
  });

  testWidgets('excludes current owner from transfer candidates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationChangeOwnerPage(organization: sampleOrg),
      ),
    );

    expect(find.text('Lê Thị Lan'), findsNothing);
    expect(find.text('Trần Thị Hoa'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
  });

  testWidgets('Continue is disabled until a member is selected; tap again unselects', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationChangeOwnerPage(organization: sampleOrg),
      ),
    );

    final continueFinder = find.widgetWithText(VButton, 'Tiếp tục');
    expect(tester.widget<VButton>(continueFinder).onPressed, isNull);

    await tester.tap(find.text('Trần Thị Hoa'));
    await tester.pumpAndSettle();
    expect(tester.widget<VButton>(continueFinder).onPressed, isNotNull);

    await tester.tap(find.text('Trần Thị Hoa'));
    await tester.pumpAndSettle();
    expect(tester.widget<VButton>(continueFinder).onPressed, isNull);
  });

  testWidgets('does not render hard-coded members when organization is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationChangeOwnerPage(organization: emptyOrg),
      ),
    );

    expect(find.text('Trần Thị Hoa'), findsNothing);
    expect(find.text('Nguyễn Văn Minh'), findsNothing);
    expect(find.text('Phạm Ngọc Mai'), findsNothing);
    expect(find.text('Chưa có thành viên đang hoạt động'), findsOneWidget);
  });

  testWidgets(
    'Tapping member card updates radio selection and clicking Tiếp tục opens confirmation sheet',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OrganizationChangeOwnerPage(organization: sampleOrg),
        ),
      );

      // Tap on candidate (Nguyễn Văn Minh)
      await tester.tap(find.text('Nguyễn Văn Minh'));
      await tester.pumpAndSettle();

      // Click Tiếp tục
      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.byType(OrganizationChangeOwnerConfirmationBottomSheet), findsOneWidget);
      expect(find.text('Chuyển quyền sở hữu cho Nguyễn Văn Minh?'), findsOneWidget);
      expect(find.text('Chuyển quyền'), findsOneWidget);
    },
  );
}
