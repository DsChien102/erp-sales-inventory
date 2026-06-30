import 'package:flutter/material.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import 'package:vet45_design_system/design_system.dart';
import '../foundation/v_context_extensions.dart';

class VCreateOrderButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const VCreateOrderButton({
    super.key,
    this.title = 'Tạo đơn hàng',
    this.subtitle = 'Tạo thông tin đơn hàng',
    this.icon = Icons.add,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dynamicColors.primary,
              borderRadius: BorderRadius.circular(VRadius.r12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: VTypography.headingH4.copyWith(
                    fontWeight: FontWeight.w600,
                    color: dynamicColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: VTypography.caption.copyWith(
                    color: dynamicColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: VSpacing.space2),
          Icon(
            Icons.chevron_right,
            color: dynamicColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
