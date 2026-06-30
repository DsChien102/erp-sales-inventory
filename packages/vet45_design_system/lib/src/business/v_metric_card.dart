import 'package:flutter/material.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import 'package:vet45_design_system/design_system.dart';
import '../foundation/v_context_extensions.dart';

class VMetricCard extends StatelessWidget {
  final Widget icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback? onTap;

  const VMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.iconBgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(VRadius.r8),
            ),
            alignment: Alignment.center,
            child: IconTheme(
              data: IconThemeData(
                color: iconColor,
                size: 16,
              ),
              child: icon,
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          Text(
            value,
            style: VTypography.headingH3.copyWith(
              color: dynamicColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: VTypography.caption.copyWith(
              color: dynamicColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
