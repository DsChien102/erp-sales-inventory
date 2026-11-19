import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class SettingsNavigationItem extends StatelessWidget {
  const SettingsNavigationItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space4,
      ),
      child: Row(
        children: [
          VIconBox(
            icon: icon,
            size: 40,
            iconSize: 20,
            backgroundColor: colors.surfaceAlt,
            iconColor: colors.textSecondary,
            borderRadius: VRadius.r12,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  title,
                  variant: VTextVariant.headingH4,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  subtitle,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          VIcon(
            icon: VIcons.chevronRight,
            color: colors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
