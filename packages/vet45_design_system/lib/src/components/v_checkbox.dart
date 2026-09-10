import 'package:flutter/material.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_inspector_scope.dart';

class VCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? label;
  final bool? enabled;
  final VComponentTone tone;
  final String? semanticLabel;

  const VCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled,
    this.tone = VComponentTone.primary,
    this.semanticLabel,
  });

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
    final isEnabled = VComponentScope.resolveEnabled(context, local: enabled);

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
        width: VBorders.thin,
      ),
    );

    checkbox = Semantics(
      checked: value,
      enabled: isEnabled,
      label: semanticLabel ?? label ?? 'Checkbox',
      child: checkbox,
    );

    if (label != null) {
      return vInspectorHide(
        vDisabledOpacity(
          enabled: isEnabled,
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
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
                        color: dynamicColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return vInspectorHide(
      vDisabledOpacity(enabled: isEnabled, child: checkbox),
    );
  }
}
