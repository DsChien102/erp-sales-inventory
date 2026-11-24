import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Skeleton placeholder matching [SalesDraftListCard] layout (SG-01 first load).
class SalesDraftListCardSkeleton extends StatelessWidget {
  const SalesDraftListCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VSkeleton(width: 160, height: 18, borderRadius: VRadius.r4),
              VGap.horizontalSm(),
              VSkeleton(width: 72, height: 18, borderRadius: VRadius.r4),
            ],
          ),
          VGap.sm(),
          Row(
            children: [
              VSkeleton(width: 90, height: 12, borderRadius: VRadius.r4),
              VGap.horizontalSm(),
              VSkeleton(width: 72, height: 12, borderRadius: VRadius.r4),
            ],
          ),
          VGap.sm(),
          VSkeleton(width: 120, height: 12, borderRadius: VRadius.r4),
          VGap.sm(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VSkeleton(width: 120, height: 12, borderRadius: VRadius.r4),
              VSkeleton(width: 40, height: 12, borderRadius: VRadius.r4),
            ],
          ),
        ],
      ),
    );
  }
}
