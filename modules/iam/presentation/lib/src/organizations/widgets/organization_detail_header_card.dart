import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Card hiển thị thông tin chung & Badge trạng thái ở trên cùng trang Detail.
class OrganizationDetailHeaderCard extends StatelessWidget {
  final OrganizationUiModel organization;
  final VoidCallback? onTap;

  const OrganizationDetailHeaderCard({
    super.key,
    required this.organization,
    this.onTap,
  });

  VComponentTone _resolveBadgeTone(OrganizationStatus status) {
    return switch (status) {
      OrganizationStatus.settingUp => VComponentTone.warning,
      OrganizationStatus.active => VComponentTone.success,
      OrganizationStatus.suspended => VComponentTone.danger,
      OrganizationStatus.closed => VComponentTone.danger,
      OrganizationStatus.all => VComponentTone.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          VBadge(
            label: organization.status.label,
            tone: _resolveBadgeTone(organization.status),
            variant: VBadgeVariant.soft,
            isSmall: true,
          ),
          const VGap.md(),

          // Main Info Row: Avatar Initials + Name/Code + Chevron
          Row(
            children: [
              // Initials Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(VRadius.r16),
                ),
                alignment: Alignment.center,
                child: VText(
                  organization.resolvedInitials,
                  style: VTypography.headingH4.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const VGap.horizontalMd(),

              // Name & Code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(
                      organization.name,
                      style: VTypography.bodyDefault.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const VGap.xs(),
                    VText(
                      organization.code,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
              const VGap.horizontalSm(),

              // Chevron Right
              VIcon(
                icon: VIcons.chevronRight,
                size: 20,
                color: colors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
