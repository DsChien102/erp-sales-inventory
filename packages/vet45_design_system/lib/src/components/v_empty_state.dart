import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class VEmptyState extends StatelessWidget {
  final String? iconEmoji;
  final IconData? iconData;
  final String title;
  final String description;
  final String? actionLabel;
  final Widget? actionLeadingIcon;
  final VoidCallback? onActionPressed;

  const VEmptyState({
    super.key,
    this.iconEmoji,
    this.iconData,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionLeadingIcon,
    this.onActionPressed,
  }) : assert(
         iconEmoji != null || iconData != null,
         'Either iconEmoji or iconData must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null)
            VIconBox(
              iconData: iconData!,
              size: 64,
              iconSize: 28,
              backgroundColor: dynamicColors.surfaceAlt,
              iconColor: dynamicColors.textSecondary,
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
          const SizedBox(height: VSpacing.space2),
          Text(
            description,
            style: VTypography.bodyDefault.copyWith(
              color: dynamicColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: VSpacing.space6),
            VButton(
              label: actionLabel!,
              onPressed: onActionPressed!,
              leadingIcon: actionLeadingIcon,
              size: VButtonSize.medium,
            ),
          ],
        ],
      ),
    );
  }
}
