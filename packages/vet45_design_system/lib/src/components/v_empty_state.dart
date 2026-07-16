import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class VEmptyState extends StatelessWidget {
  final String? iconEmoji;
  final VIcons? icon;
  final IconData? iconData;
  final String title;
  final String? description;
  final String? actionLabel;
  final Widget? actionLeadingIcon;
  final VoidCallback? onActionPressed;
  final VComponentTone? tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  const VEmptyState({
    super.key,
    this.iconEmoji,
    this.icon,
    this.iconData,
    required this.title,
    this.description,
    this.actionLabel,
    this.actionLeadingIcon,
    this.onActionPressed,
    this.tone,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  }) : assert(
         iconEmoji != null || icon != null || iconData != null,
         'Either iconEmoji, icon, or iconData must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Semantics(
      label: semanticLabel ?? title,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null || iconData != null)
              VIconBox(
                icon: icon,
                iconData: icon == null ? iconData : null,
                size: 64,
                iconSize: 28,
                tone: tone ?? VComponentTone.neutral,
                backgroundColor: tone == null ? dynamicColors.surfaceAlt : null,
                iconColor: tone == null ? dynamicColors.textSecondary : null,
                borderRadius: VRadius.r16,
              )
            else if (iconEmoji != null)
              Text(
                iconEmoji!,
                style: const TextStyle(fontSize: 48),
              ),
            const SizedBox(height: VSpacing.space4),
            Text(
              title,
              style: VTypography.headingH3.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: VSpacing.space2),
              Text(
                description!,
                style: VTypography.bodyDefault.copyWith(
                  color: dynamicColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: VSpacing.space6),
              VButton(
                label: actionLabel!,
                onPressed: onActionPressed!,
                leadingIcon: actionLeadingIcon,
                size: VButtonSize.medium,
                emphasis: emphasis,
                tone: tone == VComponentTone.primary ? VComponentTone.primary : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
