import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:admin/features/iam/presentation/organizations/models/organization_ui_model.dart';
import 'package:admin/features/iam/presentation/organizations/views/organization_detail_page.dart';
import 'package:admin/features/iam/presentation/organizations/widgets/organization_actions_bottom_sheet.dart';
import 'package:admin/features/iam/presentation/organizations/widgets/organization_restore_confirmation_bottom_sheet.dart';
import 'package:admin/features/iam/presentation/organizations/widgets/organization_suspend_confirmation_bottom_sheet.dart';
import 'package:admin/features/iam/presentation/organizations/widgets/owner_invitation_resend_sheet.dart';

void main() {
  testWidgets('Active organization shows suspend action bottom sheet option', (tester) async {
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
    expect(find.text('Gửi lại email'), findsNothing);
  });

  testWidgets('Suspended organization shows restore action bottom sheet option', (tester) async {
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
    expect(find.text('Gửi lại email'), findsNothing);
  });

  testWidgets('Setting-up organization shows only resend owner invitation action', (
    tester,
  ) async {
    const settingUpOrg = OrganizationUiModel(
      id: 'org-setup',
      name: 'Setup Store',
      code: 'TEN-SETUP',
      status: OrganizationStatus.settingUp,
      ownerInvitationEmail: 'owner@example.com',
      ownerInvitationState: 'pending',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: settingUpOrg),
      ),
    );

    expect(find.text('Thao tác'), findsOneWidget);
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.byType(OrganizationActionsBottomSheet), findsOneWidget);
    expect(find.text('Gửi lại email'), findsOneWidget);
    expect(
      find.text('Gửi lại liên kết thiết lập cho Chủ sở hữu'),
      findsOneWidget,
    );
    expect(find.text('Thay đổi chủ sở hữu'), findsNothing);
    expect(find.text('Tạm ngừng tổ chức'), findsNothing);
    expect(find.text('Khôi phục tổ chức'), findsNothing);
    expect(find.text('Đóng tổ chức'), findsNothing);
  });

  testWidgets('Setting-up organization with active owner shows only change owner action', (
    tester,
  ) async {
    const settingUpOrg = OrganizationUiModel(
      id: 'org-setup-owner',
      name: 'Setup Store With Owner',
      code: 'TEN-SETUP-OWNER',
      status: OrganizationStatus.settingUp,
      ownerUserId: 'owner-user-id',
      ownerInvitationState: 'accepted',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: settingUpOrg),
      ),
    );

    expect(find.text('Thao tác'), findsOneWidget);
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.byType(OrganizationActionsBottomSheet), findsOneWidget);
    expect(find.text('Thay đổi chủ sở hữu'), findsOneWidget);
    expect(find.text('Gửi lại email'), findsNothing);
    expect(find.text('Tạm ngừng tổ chức'), findsNothing);
    expect(find.text('Khôi phục tổ chức'), findsNothing);
    expect(find.text('Đóng tổ chức'), findsNothing);
  });

  testWidgets('Setting-up without owner or resend-eligible invitation hides actions', (
    tester,
  ) async {
    const settingUpOrg = OrganizationUiModel(
      id: 'org-setup',
      name: 'Setup Store',
      code: 'TEN-SETUP',
      status: OrganizationStatus.settingUp,
      ownerInvitationState: 'revoked',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: settingUpOrg),
      ),
    );

    expect(find.text('Thao tác'), findsNothing);
    expect(find.byType(OrganizationActionsBottomSheet), findsNothing);
    expect(find.text('Gửi lại email'), findsNothing);
  });

  testWidgets('Tapping Gửi lại email opens OwnerInvitationResendSheet prefilled', (
    tester,
  ) async {
    const settingUpOrg = OrganizationUiModel(
      id: 'org-setup',
      name: 'Setup Store',
      code: 'TEN-SETUP',
      status: OrganizationStatus.settingUp,
      ownerInvitationEmail: 'owner@example.com',
      ownerInvitationState: 'pending',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationDetailPage(organization: settingUpOrg),
      ),
    );

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi lại email'));
    await tester.pumpAndSettle();

    expect(find.byType(OwnerInvitationResendSheet), findsOneWidget);
    expect(find.text('Gửi lại email thiết lập?'), findsOneWidget);
    expect(
      find.text(
        'Liên kết hiện tại sẽ hết hiệu lực. Kiểm tra hoặc cập nhật email trước khi gửi lại.',
      ),
      findsOneWidget,
    );
    expect(find.text('Email nhận liên kết'), findsOneWidget);
    expect(find.text('Có thể sửa email trước khi gửi lại.'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Gửi'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Hủy'), findsOneWidget);
    expect(find.text('owner@example.com'), findsOneWidget);
  });

  testWidgets('Tapping suspend option opens Suspend Confirmation Bottom Sheet', (tester) async {
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

    expect(find.byType(OrganizationSuspendConfirmationBottomSheet), findsOneWidget);
    expect(find.text('Tạm ngừng tổ chức?'), findsOneWidget);
    expect(find.byType(VTextField), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
  });

  testWidgets('Tapping restore option opens Restore Confirmation Bottom Sheet', (tester) async {
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

    expect(find.byType(OrganizationRestoreConfirmationBottomSheet), findsOneWidget);
    expect(find.text('Khôi phục tổ chức?'), findsOneWidget);
    expect(find.byType(VTextField), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
  });

  testWidgets('Tapping confirm without reason keeps sheet open and shows validation', (
    tester,
  ) async {
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

    expect(
      find.byType(OrganizationSuspendConfirmationBottomSheet),
      findsOneWidget,
    );
    expect(find.text('Vui lòng nhập lý do.'), findsOneWidget);
    expect(find.byType(VToast), findsNothing);
  });

  testWidgets('Tapping confirm with reason in Suspend Confirmation shows VToast success', (
    tester,
  ) async {
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

    await tester.enterText(find.byType(TextField), 'Rà soát rủi ro truy cập');
    await tester.pump();

    await tester.tap(find.widgetWithText(VButton, 'Tạm ngừng'));
    await tester.pumpAndSettle();

    expect(find.byType(VToast), findsOneWidget);
    expect(find.text('Đã tạm ngừng tổ chức thành công.'), findsOneWidget);
  });

  testWidgets('Tapping confirm in Restore Confirmation shows VToast success notification', (
    tester,
  ) async {
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
