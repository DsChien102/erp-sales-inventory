import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Skeleton placeholder for [PartnerListItemTile].
class PartnerListItemSkeletonTile extends StatelessWidget {
  const PartnerListItemSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VSkeleton(
      height: 128,
      borderRadius: VRadius.card,
      color: colors.borderDefault,
    );
  }
}
