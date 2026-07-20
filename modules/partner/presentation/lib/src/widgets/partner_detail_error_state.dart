import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerDetailErrorState extends StatelessWidget {
  final VIcons icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const PartnerDetailErrorState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onActionPressed,
  });

  Widget _buildIllustration(BuildContext context, VColorScheme colors) {
    // Shield with question mark (D-06C - No Permission)
    if (icon == VIcons.lock) {
      return Stack(
        alignment: Alignment.center,
        children: [
          VIcon(
            icon: VIcons.shield,
            size: 120,
            color: colors.textMuted.withValues(alpha: 0.15),
          ),
          Positioned(
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(VSpacing.space3),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderDefault, width: 2),
              ),
              child: VText(
                '?',
                variant: VTextVariant.headingH1,
                color: colors.textSecondary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    // Document with magnifying glass and ? (D-06B - Not Found)
    if (icon == VIcons.search) {
      return SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Document background
            Positioned(
              top: 10,
              left: 20,
              child: VIcon(
                icon: VIcons.description,
                size: 90,
                color: colors.textMuted.withValues(alpha: 0.2),
              ),
            ),
            // Question mark inside document
            Positioned(
              top: 36,
              left: 54,
              child: VText(
                '?',
                variant: VTextVariant.headingH2,
                color: colors.textMuted.withValues(alpha: 0.4),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            // Magnifying glass overlay
            Positioned(
              bottom: 10,
              right: 15,
              child: VIcon(
                icon: VIcons.search,
                size: 64,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Fallback IconBox
    return VIconBox(
      icon: icon,
      size: 64,
      iconSize: 28,
      backgroundColor: colors.surfaceAlt,
      iconColor: colors.textSecondary,
      borderRadius: VRadius.r16,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.space6, vertical: VSpacing.space8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIllustration(context, colors),
          const SizedBox(height: VSpacing.space6),
          VText(
            title,
            variant: VTextVariant.headingH3,
            color: colors.textPrimary,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: VSpacing.space3),
          VText(
            description,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: VSpacing.space8),
          SizedBox(
            width: 220,
            child: VButton(
              label: actionLabel,
              onPressed: onActionPressed,
              variant: VButtonVariant.outline,
              foregroundColor: colors.success,
              size: VButtonSize.medium,
            ),
          ),
        ],
      ),
    );
  }
}
