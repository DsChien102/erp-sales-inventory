import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/platform_tenant.dart';
import '../models/platform_tenant_ui.dart';

/// Thẻ tổ chức ở C1: tên, trạng thái, mã, Chủ sở hữu, số thành viên.
class PlatformOrganizationCard extends StatelessWidget {
  const PlatformOrganizationCard({super.key, required this.tenant, this.onTap});

  final PlatformTenantSummary tenant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final owner = tenant.ownerName ?? tenant.ownerEmail;
    final subtitle = [
      tenant.code,
      if (owner != null) 'Chủ sở hữu: $owner',
      '${tenant.memberCount} thành viên',
    ].join(' · ');

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space4,
      ),
      child: Row(
        children: [
          VIcon(icon: VIcons.apartment, size: 20, color: colors.textPrimary),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: VText(
                        tenant.name,
                        variant: VTextVariant.bodyDefault,
                        style: VTypography.bodyDefault.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const VGap.horizontalSm(),
                    VBadge(
                      label: tenant.status.label,
                      tone: tenant.status.tone,
                      variant: VBadgeVariant.soft,
                      isSmall: true,
                    ),
                  ],
                ),
                const VGap.xs(),
                VText(
                  subtitle,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          VIcon(icon: VIcons.chevronRight, size: 20, color: colors.textSecondary),
        ],
      ),
    );
  }
}
