import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// White bordered card used for overview sections.
class PartnerDetailSectionCard extends StatelessWidget {
  const PartnerDetailSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            title,
            variant: VTextVariant.bodyDefault,
            color: colors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: VSpacing.space2),
          child,
        ],
      ),
    );
  }
}

class PartnerDetailEmptyHint extends StatelessWidget {
  const PartnerDetailEmptyHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VText(
      message,
      variant: VTextVariant.bodySmall,
      color: colors.textSecondary,
    );
  }
}

/// Label left, value right-aligned, optional trailing action icon.
class PartnerDetailInfoRow extends StatelessWidget {
  const PartnerDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.trailingIcon,
    this.isLast = false,
  });

  final String label;
  final String value;
  final VIcons? trailingIcon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : VSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: VText(
              label,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: VText(
              value,
              textAlign: TextAlign.right,
              variant: VTextVariant.bodyDefault,
              color: colors.textPrimary,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: VSpacing.space2),
            VIcon(icon: trailingIcon, size: 18, color: colors.primary),
          ],
        ],
      ),
    );
  }
}

/// Date on the left; activity text on the right.
class PartnerDetailActivityRow extends StatelessWidget {
  const PartnerDetailActivityRow({
    super.key,
    required this.dateLabel,
    required this.activityText,
  });

  final String dateLabel;
  final String activityText;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          dateLabel,
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const SizedBox(width: VSpacing.space3),
        Expanded(
          child: VText(
            activityText,
            textAlign: TextAlign.right,
            variant: VTextVariant.bodyDefault,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
