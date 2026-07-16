import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Skeleton placeholder matching [PartnerListItemTile] layout.
class PartnerListItemSkeletonTile extends StatelessWidget {
  const PartnerListItemSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VSkeleton.circle(size: 40),
          SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: VSkeleton(width: 140, height: 16)),
                    VGap.horizontalSm(),
                    VSkeleton(width: 72, height: 18, borderRadius: VRadius.r4),
                  ],
                ),
                SizedBox(height: VSpacing.space1),
                VSkeleton(width: 120, height: 12),
                SizedBox(height: VSpacing.space1),
                VSkeleton(width: 100, height: 12),
                SizedBox(height: VSpacing.space1),
                VSkeleton(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
