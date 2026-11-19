import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class SettingsInfoRow extends StatelessWidget {
  const SettingsInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines,
    this.overflow,
    this.trailing,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final int? maxLines;
  final TextOverflow? overflow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VText(
            label,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: VText(
                    value,
                    variant: VTextVariant.bodyDefault,
                    color: valueColor ?? colors.textPrimary,
                    textAlign: TextAlign.end,
                    maxLines: maxLines,
                    overflow: overflow,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing != null) ...[
                  const VGap.horizontalSm(),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
