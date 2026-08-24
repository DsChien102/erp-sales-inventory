import 'package:flutter/material.dart';
import 'package:vet45_design_system/src/patterns/v_gap.dart';

import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_inspector_scope.dart';

class VRadio<T> extends StatelessWidget {
  const VRadio({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
    this.tone = VComponentTone.primary,
    this.state,
    this.semanticLabel,
  });

  final T value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final bool enabled;
  final VComponentTone tone;
  final VComponentState? state;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final registry = RadioGroup.maybeOf<T>(context);
    final resolvedState =
        state ??
        (!enabled
            ? VComponentState.disabled
            : (onChanged != null || registry != null
                  ? VComponentState.enabled
                  : VComponentState.disabled));
    final isEnabled = resolvedState == VComponentState.enabled;

    final activeColor = switch (tone) {
      VComponentTone.danger => dynamicColors.danger,
      VComponentTone.success => dynamicColors.success,
      VComponentTone.warning => dynamicColors.warning,
      _ => dynamicColors.primary,
    };

    Widget radio = Radio<T>(
      value: value,
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return dynamicColors.textMuted;
        }
        return activeColor;
      }),
    );

    radio = Semantics(
      enabled: isEnabled,
      label: semanticLabel ?? label ?? 'Radio option',
      child: radio,
    );

    void select() {
      if (!isEnabled) return;
      if (onChanged != null) {
        onChanged!(value);
        return;
      }
      registry?.onChanged(value);
    }

    if (label != null) {
      return vInspectorHide(
        InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: isEnabled && (onChanged != null || registry != null) ? select : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                radio,
                const VGap.sm(),
                Flexible(
                  child: Text(
                    label!,
                    style: VTypography.bodyDefault.copyWith(
                      color: isEnabled ? dynamicColors.textPrimary : dynamicColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return vInspectorHide(radio);
  }
}
