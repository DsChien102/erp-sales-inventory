import 'package:erp/core/iam/iam_role_label_mapper.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/platform_tenant.dart';
import '../models/platform_tenant_ui.dart';

/// Thẻ "Chủ sở hữu" ở C2.
class PlatformOrganizationOwnerCard extends StatelessWidget {
  const PlatformOrganizationOwnerCard({super.key, required this.detail});

  final PlatformTenantDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final name = detail.ownerName ?? detail.ownerEmail ?? 'Chưa xác định';
    final email = detail.ownerName == null ? null : detail.ownerEmail;
    final role = IamRoleLabelMapper.toDisplayLabel(detail.ownerRoleLabel);

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Chủ sở hữu',
            style: VTypography.bodyDefault.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.md(),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(VRadius.r12),
                ),
                alignment: Alignment.center,
                child: VText(
                  initialsOf(name, fallback: 'SH'),
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(
                      name,
                      style: VTypography.bodyDefault.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email != null && email.isNotEmpty) ...[
                      const VGap.xs(),
                      VText(
                        email,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (role.isNotEmpty)
                VText(
                  role,
                  style: VTypography.bodySmall.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
