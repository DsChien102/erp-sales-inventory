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
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dynamicColors.warningBg,
          border: Border.all(
            color: dynamicColors.warning.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: dynamicColors.warning,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cần bổ sung ($blockersCount)',
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bấm để xem checklist và bổ sung từng mục.',
                    style: VTypography.bodySmall.copyWith(
                      color: dynamicColors.warning,
                    ),
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
