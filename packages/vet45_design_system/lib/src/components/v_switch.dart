import 'package:flutter/material.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_inspector_scope.dart';

class VSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool? enabled;
  final VComponentTone tone;
  final String? semanticLabel;

  const VSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.enabled,
    this.tone = VComponentTone.primary,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isEnabled =
        VComponentScope.resolveEnabled(context, local: enabled) && onChanged != null;

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
      return vInspectorHide(
        InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
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
        ),
      );
    }

    return vInspectorHide(toggle);
  }
}
