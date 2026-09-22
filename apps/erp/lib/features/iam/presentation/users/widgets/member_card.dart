import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';

class MemberCard extends StatelessWidget {
  final MemberUiModel member;
  final VoidCallback? onTap;

  const MemberCard({
    super.key,
    required this.member,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    // Keep labels aligned with the member detail badge so a removed member
    // never reads as merely "Tạm ngừng" in the list.
    final (badgeLabel, badgeTone) = switch (member.status) {
      MemberStatus.active => ('Hoạt động', VComponentTone.success),
      MemberStatus.suspended => ('Tạm ngừng', VComponentTone.danger),
      MemberStatus.removed => ('Đã loại', VComponentTone.danger),
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
                  member.name,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  '${member.email} · ${member.role}',
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
