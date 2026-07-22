import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/src/organizations/models/organization_ui_model.dart';
import 'package:vet45_iam_presentation/src/organizations/views/organization_detail_page.dart';
import 'package:vet45_iam_presentation/src/organizations/widgets/organization_actions_bottom_sheet.dart';
import 'package:vet45_iam_presentation/src/organizations/widgets/organization_restore_confirmation_bottom_sheet.dart';
import 'package:vet45_iam_presentation/src/organizations/widgets/organization_suspend_confirmation_bottom_sheet.dart';

void main() {
  testWidgets('Active organization shows suspend action bottom sheet option',
      (tester) async {
    const activeOrg = OrganizationUiModel(
      id: 'org-1',
      name: 'Active Store',
      code: 'TEN-000001',
      status: OrganizationStatus.active,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: activeOrg),
      ),
    );

    expect(find.text('Thao tác'), findsOneWidget);
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.byType(OrganizationActionsBottomSheet), findsOneWidget);
    expect(find.text('Thay đổi chủ sở hữu'), findsOneWidget);
    expect(find.text('Tạm ngừng tổ chức'), findsOneWidget);
  });

  testWidgets(
      'Suspended organization shows restore action bottom sheet option',
      (tester) async {
    const suspendedOrg = OrganizationUiModel(
      id: 'org-2',
      name: 'Suspended Store',
      code: 'TEN-000002',
      status: OrganizationStatus.suspended,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: suspendedOrg),
      ),
    );

    expect(find.text('Thao tác'), findsOneWidget);
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.byType(OrganizationActionsBottomSheet), findsOneWidget);
    expect(find.text('Thay đổi chủ sở hữu'), findsOneWidget);
    expect(find.text('Khôi phục tổ chức'), findsOneWidget);
  });

  testWidgets(
      'Tapping suspend option opens Suspend Confirmation Bottom Sheet',
      (tester) async {
    const activeOrg = OrganizationUiModel(
      id: 'org-1',
      name: 'Active Store',
      code: 'TEN-000001',
      status: OrganizationStatus.active,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: activeOrg),
      ),
    );

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạm ngừng tổ chức'));
    await tester.pumpAndSettle();

    expect(
        find.byType(OrganizationSuspendConfirmationBottomSheet), findsOneWidget);
    expect(find.text('Tạm ngừng tổ chức?'), findsOneWidget);
    expect(find.byType(VTextField), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
  });

  testWidgets(
      'Tapping restore option opens Restore Confirmation Bottom Sheet',
      (tester) async {
    const suspendedOrg = OrganizationUiModel(
      id: 'org-2',
      name: 'Suspended Store',
      code: 'TEN-000002',
      status: OrganizationStatus.suspended,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: suspendedOrg),
      ),
    );

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Khôi phục tổ chức'));
    await tester.pumpAndSettle();

    expect(
        find.byType(OrganizationRestoreConfirmationBottomSheet), findsOneWidget);
    expect(find.text('Khôi phục tổ chức?'), findsOneWidget);
    expect(find.byType(VTextField), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
  });

  testWidgets(
      'Tapping confirm in Suspend Confirmation shows VToast success notification',
      (tester) async {
    const activeOrg = OrganizationUiModel(
      id: 'org-1',
      name: 'Active Store',
      code: 'TEN-000001',
      status: OrganizationStatus.active,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: activeOrg),
      ),
    );

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạm ngừng tổ chức'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Tạm ngừng'));
    await tester.pumpAndSettle();

    expect(find.byType(VToast), findsOneWidget);
    expect(find.text('Đã tạm ngừng tổ chức thành công.'), findsOneWidget);
  });

  testWidgets(
      'Tapping confirm in Restore Confirmation shows VToast success notification',
      (tester) async {
    const suspendedOrg = OrganizationUiModel(
      id: 'org-2',
      name: 'Suspended Store',
      code: 'TEN-000002',
      status: OrganizationStatus.suspended,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: suspendedOrg),
      ),
    );

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Khôi phục tổ chức'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Khôi phục'));
    await tester.pumpAndSettle();

    expect(find.byType(VToast), findsOneWidget);
    expect(find.text('Đã khôi phục tổ chức thành công.'), findsOneWidget);
  });
}
