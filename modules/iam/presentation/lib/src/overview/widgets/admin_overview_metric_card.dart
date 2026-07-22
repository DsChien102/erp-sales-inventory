import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Card hiển thị chỉ số thống kê trong Tổng quan quản trị.
class AdminOverviewMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;

  const AdminOverviewMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      backgroundColor: colors.surface,
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            label,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const VGap.xs(),
          VText(
            value,
            style: VTypography.headingH1.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.xs(),
          VText(
            subtext,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
