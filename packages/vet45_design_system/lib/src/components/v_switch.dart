import 'package:flutter/material.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';

class VSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool enabled;
  final VComponentTone tone;
  final VComponentState? state;
  final String? semanticLabel;

  const VSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.enabled = true,
    this.tone = VComponentTone.primary,
    this.state,
    this.semanticLabel,
  });

  VComponentState _resolveState() {
    if (state != null) return state!;
    if (!enabled || onChanged == null) return VComponentState.disabled;
    return VComponentState.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolvedState = _resolveState();
    final isEnabled = resolvedState == VComponentState.enabled;

    final trackColor = switch (tone) {
      VComponentTone.danger => dynamicColors.danger,
      VComponentTone.success => dynamicColors.success,
      VComponentTone.warning => dynamicColors.warning,
      _ => dynamicColors.primary,
    };

    Widget toggle = Switch(
      value: value,
      onChanged: isEnabled ? onChanged : null,
      activeThumbColor: Colors.white,
      activeTrackColor: trackColor,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: dynamicColors.borderStrong,
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );

    toggle = Semantics(
      toggled: value,
      enabled: isEnabled,
      label: semanticLabel ?? label ?? 'Switch',
      child: toggle,
    );

    if (label != null) {
      return InkWell(
        onTap: isEnabled ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              toggle,
            ],
          ),
        ),
      );
    }

    return toggle;
  }
}
