import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class SettingsInfoRow extends StatelessWidget {
  const SettingsInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: VText(
              label,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ),
          const VGap.horizontalMd(),
          Expanded(
            child:               VText(
                value,
                variant: VTextVariant.bodyDefault,
                color: valueColor ?? colors.textPrimary,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
          ),
        ],
      ),
    );
  }
}
