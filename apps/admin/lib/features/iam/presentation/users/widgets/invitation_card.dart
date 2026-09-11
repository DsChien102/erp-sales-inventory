import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';

class InvitationCard extends StatelessWidget {
  final InvitationUiModel invitation;
  final VoidCallback? onTap;

  const InvitationCard({
    super.key,
    required this.invitation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final (badgeLabel, badgeTone) = switch (invitation.status) {
      InvitationStatus.failed => ('Lỗi gửi', VComponentTone.danger),
      InvitationStatus.pending => ('Đang chờ', VComponentTone.warning),
      InvitationStatus.expiring => ('Sắp hết hạn', VComponentTone.danger),
      InvitationStatus.accepted => ('Đã chấp nhận', VComponentTone.success),
      InvitationStatus.declined => ('Đã từ chối', VComponentTone.neutral),
      InvitationStatus.revoked => ('Đã thu hồi', VComponentTone.neutral),
      InvitationStatus.expired => ('Hết hạn', VComponentTone.neutral),
    };

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VIcon(
            icon: VIcons.person,
            size: 24,
            color: colors.textPrimary,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  invitation.email,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  invitation.statusDetail,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          VBadge(
            label: badgeLabel,
            tone: badgeTone,
            variant: VBadgeVariant.soft,
            isSmall: true,
          ),
        ],
      ),
    );
  }
}
