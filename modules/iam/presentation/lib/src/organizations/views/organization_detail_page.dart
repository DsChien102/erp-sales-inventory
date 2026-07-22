import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';
import '../widgets/organization_actions_bottom_sheet.dart';
import '../widgets/organization_detail_alerts.dart';
import '../widgets/organization_detail_bottom_bar.dart';
import '../widgets/organization_detail_header_card.dart';
import '../widgets/organization_detail_members_card.dart';
import '../widgets/organization_detail_owner_card.dart';
import '../widgets/organization_detail_platform_info_card.dart';
import '../widgets/organization_restore_confirmation_bottom_sheet.dart';
import '../widgets/organization_suspend_confirmation_bottom_sheet.dart';
import 'organization_change_owner_page.dart';

/// Trang Chi tiết Tổ chức (Organization Detail Page).
class OrganizationDetailPage extends StatefulWidget {
  final OrganizationUiModel organization;
  final VoidCallback? onBackPressed;
  final VoidCallback? onActionTap;
  final bool showSuccessToastOnBuild;

  const OrganizationDetailPage({
    super.key,
    required this.organization,
    this.onBackPressed,
    this.onActionTap,
    this.showSuccessToastOnBuild = false,
  });

  @override
  State<OrganizationDetailPage> createState() => _OrganizationDetailPageState();
}

class _OrganizationDetailPageState extends State<OrganizationDetailPage> {
  @override
  void initState() {
    super.initState();
    if (widget.showSuccessToastOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã khởi tạo tổ chức thành công.',
            type: VToastType.success,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: VAppBar(
        title: 'Chi tiết tổ chức',
        showBackButton: true,
        leading: IconButton(
          icon: VIcon(
            icon: VIcons.arrowLeft,
            color: colors.textPrimary,
          ),
          onPressed: widget.onBackPressed ?? () => Navigator.of(context).maybePop(true),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        child: Column(
          children: [
            // Top Header Card
            OrganizationDetailHeaderCard(
              organization: widget.organization,
            ),
            const VGap.md(),

            // Warning / Status Alerts
            OrganizationDetailAlerts(
              organization: widget.organization,
            ),

            // Active -> Members list card; Others -> Owner card
            if (widget.organization.status == OrganizationStatus.active) ...[
              OrganizationDetailMembersCard(
                organization: widget.organization,
              ),
            ] else ...[
              OrganizationDetailOwnerCard(
                organization: widget.organization,
              ),
            ],
            const VGap.md(),

            // Platform Info Card
            OrganizationDetailPlatformInfoCard(
              organization: widget.organization,
            ),
            const VGap.xl(),
          ],
        ),
      ),
      bottomNavigationBar: widget.organization.status == OrganizationStatus.closed
          ? null
          : OrganizationDetailBottomBar(
              onActionTap: widget.onActionTap ?? () => _handleActionTap(context),
            ),
    );
  }

  void _handleActionTap(BuildContext context) {
    showVBottomSheet(
      context: context,
      child: OrganizationActionsBottomSheet(
        organization: widget.organization,
        onChangeOwnerTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => OrganizationChangeOwnerPage(
                organization: widget.organization,
              ),
            ),
          );
          if (result == true && context.mounted) {
            VToast.show(
              context,
              title: 'Thành công',
              message: 'Đã chuyển quyền sở hữu.',
              type: VToastType.success,
            );
          }
        },
        onSuspendTap: () => _showSuspendConfirmation(context),
        onRestoreTap: () => _showRestoreConfirmation(context),
      ),
    );
  }

  void _showSuspendConfirmation(BuildContext context) {
    showVBottomSheet(
      context: context,
      child: OrganizationSuspendConfirmationBottomSheet(
        onConfirm: (reason) {
          final isError = reason.trim().toLowerCase() == 'error' ||
              reason.trim().toLowerCase() == 'lỗi';
          if (isError) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: 'Không thể tạm ngừng tổ chức. Vui lòng thử lại.',
              type: VToastType.danger,
            );
          } else {
            VToast.show(
              context,
              title: 'Thành công',
              message: 'Đã tạm ngừng tổ chức thành công.',
              type: VToastType.success,
            );
          }
        },
      ),
    );
  }

  void _showRestoreConfirmation(BuildContext context) {
    showVBottomSheet(
      context: context,
      child: OrganizationRestoreConfirmationBottomSheet(
        onConfirm: (reason) {
          final isError = reason.trim().toLowerCase() == 'error' ||
              reason.trim().toLowerCase() == 'lỗi';
          if (isError) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: 'Không thể khôi phục tổ chức. Vui lòng thử lại.',
              type: VToastType.danger,
            );
          } else {
            VToast.show(
              context,
              title: 'Thành công',
              message: 'Đã khôi phục tổ chức thành công.',
              type: VToastType.success,
            );
          }
        },
      ),
    );
  }
}
