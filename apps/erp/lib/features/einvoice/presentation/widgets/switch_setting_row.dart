import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class SwitchSettingRow extends StatelessWidget {
  const SwitchSettingRow({
    super.key,
    required this.label,
    required this.supportingText,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String supportingText;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: VText(
                  label,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const VGap.horizontalMd(),
              VSwitch(
                value: value,
                enabled: enabled,
                onChanged: enabled ? onChanged : null,
                semanticLabel: label,
              ),
            ],
          ),
          const VGap.xs(),
          VText(
            supportingText,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}
