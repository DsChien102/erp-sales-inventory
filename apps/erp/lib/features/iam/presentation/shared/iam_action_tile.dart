import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class IamActionTile extends StatelessWidget {
  const IamActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final VIcons icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final foreground = isDanger ? colors.danger : colors.textPrimary;

    return Semantics(
      button: true,
      enabled: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.card),
        child: Container(
          padding: const EdgeInsets.all(VSpacing.space4),
          decoration: BoxDecoration(
            color: isDanger ? colors.dangerBg : colors.surface,
            border: Border.all(
              color: isDanger ? colors.danger : colors.borderDefault,
            ),
            borderRadius: BorderRadius.circular(VRadius.card),
          ),
          child: Row(
            children: [
              VIcon(icon: icon, size: 24, color: foreground),
              const VGap.horizontalMd(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      title,
                      variant: VTextVariant.bodyDefault,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const VGap.xs(),
                      VText(
                        subtitle!,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
              VIcon(
                icon: VIcons.chevronRight,
                size: 20,
                color: isDanger ? colors.danger : colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
