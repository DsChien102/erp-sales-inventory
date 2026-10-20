import 'package:flutter/material.dart';
import 'package:vet45_design_system/src/patterns/v_gap.dart';

import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_scope.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_inspector_scope.dart';

class VRadio<T> extends StatelessWidget {
  const VRadio({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled,
    this.semanticLabel,
  });

  final T value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final bool? enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final registry = RadioGroup.maybeOf<T>(context);
    final isEnabled =
        VComponentScope.resolveEnabled(context, local: enabled) &&
        (onChanged != null || registry != null);

    Widget radio = Radio<T>(
      value: value,
      enabled: isEnabled,
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return dynamicColors.primary;
        }
        return dynamicColors.borderInput;
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

    final Widget body;
    if (label != null) {
      body = InkWell(
        onTap: isEnabled && (onChanged != null || registry != null) ? select : null,
        borderRadius: BorderRadius.circular(VRadius.r4),
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
                    color: dynamicColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = radio;
    }

    return vInspectorHide(
      vDisabledOpacity(enabled: isEnabled, child: body),
    );
  }
}
