import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';

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
    required this.value,
    required this.label,
    this.hintText = 'nn/mm/yyyy',
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
    return enabled ? VComponentState.enabled : VComponentState.disabled;
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
      VComponentTone.danger => VColors.danger,
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
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: dynamicColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: VTypography.bodyDefault.copyWith(
                  color: dynamicColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: VColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
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
                color: isEnabled ? dynamicColors.background : dynamicColors.surfaceAlt,
                border: Border.all(
                  color: isEnabled ? borderColor : dynamicColors.borderDefault,
                  width: borderWidth,
                ),
                borderRadius: BorderRadius.circular(VRadius.input),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateText,
                      style: VTypography.bodyDefault.copyWith(
                        color: value != null
                            ? (isEnabled
                                ? dynamicColors.textPrimary
                                : dynamicColors.textMuted)
                            : dynamicColors.textMuted,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_month_rounded,
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
