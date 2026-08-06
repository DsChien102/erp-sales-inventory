import 'package:flutter/material.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';

class VCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? label;
  final bool enabled;
  final VComponentTone tone;
  final VComponentState? state;
  final String? semanticLabel;

  const VCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
    this.tone = VComponentTone.primary,
    this.state,
    this.semanticLabel,
  });

  VComponentState _resolveState() {
    if (state != null) return state!;
    return enabled ? VComponentState.enabled : VComponentState.disabled;
  }

  Color _activeColor(dynamic dynamicColors) {
    return switch (tone) {
      VComponentTone.danger => dynamicColors.danger,
      VComponentTone.success => dynamicColors.success,
      VComponentTone.warning => dynamicColors.warning,
      _ => dynamicColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolvedState = _resolveState();
    final isEnabled = resolvedState == VComponentState.enabled;

    Widget checkbox = Checkbox(
      value: value,
      onChanged: isEnabled ? onChanged : null,
      activeColor: _activeColor(dynamicColors),
      checkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.r4),
      ),
      side: VBorders.side(
        dynamicColors.borderStrong,
        width: VBorders.medium,
      ),
    );

    checkbox = Semantics(
      checked: value,
      enabled: isEnabled,
      label: semanticLabel ?? label ?? 'Checkbox',
      child: checkbox,
    );

    if (label != null) {
      return InkWell(
        onTap: isEnabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(VRadius.r4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              checkbox,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label!,
                  style: VTypography.bodyDefault.copyWith(
                    color: isEnabled
                        ? dynamicColors.textPrimary
                        : dynamicColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return checkbox;
  }
}
