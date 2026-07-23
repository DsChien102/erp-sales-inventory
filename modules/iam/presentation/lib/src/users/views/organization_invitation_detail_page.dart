import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';

/// Trang Chi tiết lời mời (TA-D-05, TA-D-06, TA-D-07) kèm các Bottom Sheet thao tác (TA-O-01, TA-O-02).
class OrganizationInvitationDetailPage extends StatefulWidget {
  final InvitationUiModel invitation;

  const OrganizationInvitationDetailPage({
    super.key,
    this.invitation = const InvitationUiModel(
      id: 'i2',
      email: 'banhang@minhphat.vn',
      role: 'Nhân viên bán hàng',
      statusDetail: 'Nhân viên bán hàng · Hết hạn sau 7 ngày',
      status: InvitationStatus.pending,
    ),
  });

  @override
  State<OrganizationInvitationDetailPage> createState() => _OrganizationInvitationDetailPageState();
}

class _OrganizationInvitationDetailPageState extends State<OrganizationInvitationDetailPage> {
  void _showActionBottomSheet(BuildContext context) {
    showVBottomSheet(
      context: context,
      title: 'Thao tác lời mời',
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Option 1: Gửi lại lời mời
            _buildActionItem(
              context: context,
              icon: VIcons.refresh,
              title: 'Gửi lại lời mời',
              subtitle: 'Gửi lại email đến người nhận',
              onTap: () {
                Navigator.of(context).pop();
                VToast.show(
                  context,
                  title: 'Đã gửi lại lời mời',
                  message: 'Email lời mời đã được gửi lại thành công.',
                  type: VToastType.success,
                );
              },
            ),
            const VGap.sm(),

            // Option 2: Thu hồi lời mời (Danger)
            _buildActionItem(
              context: context,
              icon: VIcons.delete,
              title: 'Thu hồi lời mời',
              subtitle: 'Người nhận không thể tiếp tục tham gia',
              isDanger: true,
              onTap: () {
                Navigator.of(context).pop(); // Close TA-O-01
                _showRevokeConfirmationBottomSheet(context); // Open TA-O-02
              },
            ),
            const VGap.md(),
          ],
        ),
      ),
    );
  }

  void _showRevokeConfirmationBottomSheet(BuildContext context) {
    final colors = context.vColors;
    showVBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VText(
              'Thu hồi lời mời?',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.danger,
              ),
            ),
            const VGap.xs(),
            VText(
              'Người nhận sẽ không thể dùng liên kết hiện tại để tham gia tổ chức.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.lg(),
            VButton(
              label: 'Quay lại',
              variant: VButtonVariant.outline,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const VGap.sm(),
            VButton(
              label: 'Thu hồi lời mời',
              variant: VButtonVariant.dangerOutline,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pop(); // Close bottom sheet
                try {
                  context.pop(true);
                } catch (_) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            const VGap.sm(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required VIcons icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final colors = context.vColors;

    final bgColor = isDanger ? colors.dangerBg : colors.surface;
    final borderColor = isDanger ? colors.danger : colors.borderDefault;
    final iconColor = isDanger ? colors.danger : colors.textPrimary;
    final titleColor = isDanger ? colors.danger : colors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VSpacing.space4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(VRadius.card),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            VIcon(
              icon: icon,
              size: 22,
              color: iconColor,
            ),
            const VGap.horizontalMd(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    title,
                    variant: VTextVariant.bodyDefault,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const VGap.xs(),
                  VText(
                    subtitle,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            VIcon(
              icon: VIcons.chevronRight,
              size: 20,
              color: isDanger ? colors.danger : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final invitation = widget.invitation;

    final (badgeLabel, badgeStatus) = switch (invitation.status) {
      InvitationStatus.failed => ('Lỗi gửi', VBadgeStatus.danger),
      InvitationStatus.pending => ('Đang chờ', VBadgeStatus.warning),
      InvitationStatus.expiring => ('Sắp hết hạn', VBadgeStatus.danger),
    };

    final (
      statusDesc,
      dateLabel,
      emailStatusText,
      bannerBg,
      bannerBorder,
      bannerIcon,
      bannerIconColor,
      bannerTitle,
      bannerTitleColor,
      bannerMsg,
    ) = switch (invitation.status) {
      InvitationStatus.failed => (
        'Lời mời còn hiệu lực · Email chưa gửi',
        'Ngày tạo',
        'Gửi thất bại',
        colors.dangerBg,
        colors.danger.withValues(alpha: 0.4),
        VIcons.error,
        colors.danger,
        'Không gửi được email',
        colors.danger,
        'Lời mời vẫn còn hiệu lực. Hãy gửi lại email hoặc thu hồi lời mời.',
      ),
      InvitationStatus.pending => (
        'Đang chờ người nhận phản hồi',
        'Ngày gửi',
        'Đã gửi',
        colors.infoBg,
        colors.info.withValues(alpha: 0.4),
        VIcons.info,
        colors.info,
        'Đang chờ người nhận',
        colors.info,
        'Người nhận chưa chấp nhận lời mời. Có thể gửi lại hoặc thu hồi trong mục Thao tác.',
      ),
      InvitationStatus.expiring => (
        'Hết hạn trong 1 ngày',
        'Ngày gửi',
        'Đã gửi',
        colors.warningBg,
        colors.warning.withValues(alpha: 0.4),
        VIcons.warning,
        colors.warning,
        'Sắp hết hạn',
        colors.warning,
        'Lời mời sẽ hết hạn trong 1 ngày. Gửi lại để tạo lời mời mới với thời hạn mới.',
      ),
    };

    return VPageScaffold(
      title: 'Chi tiết lời mời',
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: VButton(
          label: 'Thao tác',
          trailingIcon: const VIcon(
            icon: VIcons.chevronUp,
            size: 18,
            color: Colors.white,
          ),
          variant: VButtonVariant.primary,
          tone: VComponentTone.success,
          fullWidth: true,
          onPressed: () => _showActionBottomSheet(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          children: [
            // Card 1: Top summary card
            VCard(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: VText(
                          invitation.email,
                          variant: VTextVariant.headingH4,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      VBadge(
                        label: badgeLabel,
                        status: badgeStatus,
                        isSmall: true,
                      ),
                    ],
                  ),
                  const VGap.xs(),
                  VText(
                    '${invitation.role} · Thú y Minh Phát',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  const VGap.md(),
                  VText(
                    statusDesc,
                    variant: VTextVariant.bodyDefault,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const VGap.md(),

            // Card 2: Thông tin lời mời
            VCard(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    'Thông tin lời mời',
                    variant: VTextVariant.headingH4,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const VGap.md(),
                  _buildDetailRow('Tổ chức', 'Thú y Minh Phát'),
                  const VGap.sm(),
                  _buildDetailRow(dateLabel, '14/07/2026 · 17:05'),
                  const VGap.sm(),
                  _buildDetailRow('Hết hạn', '21/07/2026 · 17:05'),
                  const VGap.sm(),
                  _buildDetailRow('Trạng thái email', emailStatusText),
                ],
              ),
            ),
            const VGap.md(),

            // Card 3: Status-specific Notice Box Banner
            Container(
              padding: const EdgeInsets.all(VSpacing.space4),
              decoration: BoxDecoration(
                color: bannerBg,
                borderRadius: BorderRadius.circular(VRadius.card),
                border: Border.all(
                  color: bannerBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VIcon(
                    icon: bannerIcon,
                    size: 22,
                    color: bannerIconColor,
                  ),
                  const VGap.horizontalMd(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          bannerTitle,
                          variant: VTextVariant.bodyDefault,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: bannerTitleColor,
                          ),
                        ),
                        const VGap.xs(),
                        VText(
                          bannerMsg,
                          variant: VTextVariant.bodySmall,
                          color: colors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        VText(
          value,
          variant: VTextVariant.bodySmall,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
