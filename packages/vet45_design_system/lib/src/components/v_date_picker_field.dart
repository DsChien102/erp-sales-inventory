import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../foundations/icons/v_icons.dart';

class VDatePickerField extends StatelessWidget {
  final DateTime? value;
  final String label;
  final String hintText;
  final bool required;
  final VoidCallback onTap;
  final bool enabled;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState? state;
  final String? semanticLabel;

  const VDatePickerField({
    super.key,
    this.value,
    required this.label,
    this.hintText = 'Chọn ngày',
    this.required = false,
    required this.onTap,
    this.enabled = true,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state,
    this.semanticLabel,
  });

  VComponentState _resolveState() {
    if (state != null) return state!;
    if (!enabled) return VComponentState.disabled;
    return VComponentState.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolvedState = _resolveState();
    final isEnabled = resolvedState == VComponentState.enabled;
    final dateText = value != null
        ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
        : hintText;

    final borderColor = switch (tone) {
      VComponentTone.primary => dynamicColors.primary,
      VComponentTone.danger => dynamicColors.danger,
      _ => dynamicColors.borderDefault,
    };

    final borderWidth = emphasis == VComponentEmphasis.strong ? 1.5 : 1.0;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel ?? label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              VIcon(
                icon: VIcons.calendar,
                size: 16,
                color: dynamicColors.textSecondary,
              ),
              const SizedBox(width: 8),
              VText(
                label,
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.w600),
                color: dynamicColors.textPrimary,
              ),
              if (required) ...[
                const SizedBox(width: 4),
                VText(
                  '*',
                  variant: VTextVariant.bodyDefault,
                  color: dynamicColors.danger,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(VRadius.input),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
              decoration: BoxDecoration(
                color: !isEnabled
                    ? dynamicColors.surfaceAlt
                    : value != null
                        ? dynamicColors.surfaceAlt
                        : dynamicColors.surface,
                border: Border.all(
                  color: isEnabled ? borderColor : dynamicColors.borderDefault,
                  width: borderWidth,
                ),
                borderRadius: BorderRadius.circular(VRadius.input),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: VText(
                      dateText,
                      variant: VTextVariant.bodyDefault,
                      color: value != null
                          ? (isEnabled
                              ? dynamicColors.textPrimary
                              : dynamicColors.textMuted)
                          : dynamicColors.textMuted,
                    ),
                  ),
                  VIcon(
                    icon: VIcons.calendar,
                    size: 20,
                    color: dynamicColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
