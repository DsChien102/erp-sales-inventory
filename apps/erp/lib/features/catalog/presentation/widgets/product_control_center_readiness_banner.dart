import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductControlCenterReadinessBanner extends StatelessWidget {
  const ProductControlCenterReadinessBanner({
    super.key,
    required this.blockersCount,
    required this.onTap,
  });

  final int blockersCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return GestureDetector(
      key: const Key('btn_readiness_checklist_banner'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VSpacing.md),
        decoration: BoxDecoration(
          color: dynamicColors.warningBg,
          border: Border.all(
            color: dynamicColors.warning.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(VRadius.r12),
        ),
        child: Row(
          children: [
            VIcon(
              iconData: Icons.error_outline,
              color: dynamicColors.warning,
              size: 24,
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    'Cần bổ sung ($blockersCount)',
                    variant: VTextVariant.bodyDefault,
                    color: dynamicColors.warning,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const VGap.xs(),
                  VText(
                    'Bấm để xem checklist và bổ sung từng mục.',
                    variant: VTextVariant.bodySmall,
                    color: dynamicColors.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
