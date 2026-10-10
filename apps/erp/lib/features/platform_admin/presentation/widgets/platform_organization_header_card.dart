import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/platform_tenant.dart';
import '../models/platform_tenant_ui.dart';

/// Thẻ đầu C2: trạng thái, ô viết tắt, tên, mã.
class PlatformOrganizationHeaderCard extends StatelessWidget {
  const PlatformOrganizationHeaderCard({super.key, required this.detail});

  final PlatformTenantDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VBadge(
            label: detail.status.label,
            tone: detail.status.tone,
            variant: VBadgeVariant.soft,
            isSmall: true,
          ),
          const VGap.md(),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(VRadius.r16),
                ),
                alignment: Alignment.center,
                child: VText(
                  initialsOf(detail.name),
                  style: VTypography.headingH4.copyWith(
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
                      detail.name,
                      style: VTypography.bodyDefault.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const VGap.xs(),
                    VText(
                      detail.code,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
