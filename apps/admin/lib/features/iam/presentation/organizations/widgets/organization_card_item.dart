import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Widget hiển thị thẻ từng tổ chức trong danh sách.
class OrganizationCardItem extends StatelessWidget {
  final OrganizationUiModel organization;
  final VoidCallback? onTap;

  const OrganizationCardItem({
    super.key,
    required this.organization,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Building icon without background
          VIcon(
            icon: VIcons.apartment,
            size: 20,
            color: colors.textPrimary,
          ),
          const VGap.horizontalMd(),

          // Organization details (Title + Subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(
                  organization.name,
                  variant: VTextVariant.bodyDefault,
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const VGap.xs(),
                VText(
                  organization.type,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),

          // Right chevron icon
          VIcon(
            icon: VIcons.chevronRight,
            size: 20,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}
