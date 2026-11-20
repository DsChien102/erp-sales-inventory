import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Skeleton placeholder matching [ProductListItemTile] layout.
class ProductListItemSkeletonTile extends StatelessWidget {
  const ProductListItemSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const VCard(
      padding: EdgeInsets.all(VSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VSkeleton(
            width: 60,
            height: 60,
            borderRadius: VRadius.r8,
          ),
          VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VSkeleton(width: 160, height: 16),
                VGap.xs(),
                VSkeleton(width: 100, height: 12),
                VGap.sm(),
                Row(
                  children: [
                    Expanded(flex: 2, child: VSkeleton(width: 72, height: 14)),
                    Expanded(child: Center(child: VSkeleton(width: 40, height: 12))),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: VSkeleton(width: 36, height: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
