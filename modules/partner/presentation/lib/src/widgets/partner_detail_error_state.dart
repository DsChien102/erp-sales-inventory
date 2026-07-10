import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerDetailErrorState extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const PartnerDetailErrorState({
    super.key,
    required this.iconData,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onActionPressed,
  });

  Widget _buildIllustration(BuildContext context, VColorScheme colors) {
    // Shield with question mark (D-06C - No Permission)
    if (iconData == Icons.lock_outline_rounded) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 120,
            color: colors.textMuted.withValues(alpha: 0.15),
          ),
          Positioned(
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderDefault, width: 2),
              ),
              child: Text(
                '?',
                style: VTypography.headingH1.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Document with magnifying glass and ? (D-06B - Not Found)
    if (iconData == Icons.search_off_rounded) {
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
              child: Icon(
                Icons.description_outlined,
                size: 90,
                color: colors.textMuted.withValues(alpha: 0.2),
              ),
            ),
            // Question mark inside document
            Positioned(
              top: 36,
              left: 54,
              child: Text(
                '?',
                style: VTypography.headingH1.copyWith(
                  color: colors.textMuted.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
            // Magnifying glass overlay
            Positioned(
              bottom: 10,
              right: 15,
              child: Icon(
                Icons.search,
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
      iconData: iconData,
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
          Text(
            title,
            style: VTypography.headingH3.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpacing.space3),
          Text(
            description,
            style: VTypography.bodyDefault.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
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
