import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_field.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';

/// Calendar icon placement inside [VDatePicker] control.
enum VDatePickerIconPosition {
  /// Leading (LTR left). Default.
  left,

  /// Trailing (LTR right).
  right,
}

class VDatePicker extends StatefulWidget {
  final DateTime? value;
  @Deprecated('Use VField + VFieldLabel instead')
  final String label;
  final String hintText;
  @Deprecated('Use VFieldLabel(..., isRequired: true) instead')
  final bool required;
  final ValueChanged<DateTime>? onChanged;

  /// When set, skips the built-in [showDatePicker] and runs this instead
  /// (e.g. custom clear / pick flows).
  final VoidCallback? onTap;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final bool? enabled;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  /// Calendar icon side. Defaults to [VDatePickerIconPosition.left].
  final VDatePickerIconPosition iconPosition;

  const VDatePicker({
    super.key,
    this.value,
    @Deprecated('Use VField + VFieldLabel instead') required this.label,
    this.hintText = 'Chọn ngày',
    @Deprecated('Use VFieldLabel(..., isRequired: true) instead') this.required = false,
    this.onChanged,
    this.onTap,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.enabled,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
    this.iconPosition = VDatePickerIconPosition.left,
  });

  @override
  State<VDatePicker> createState() => _VDatePickerState();
}

class _VDatePickerState extends State<VDatePicker> {
  bool _highlighted = false;

  void _handleTap() {
    // Keep this sync — do not await in the InkWell gesture callback.
    unawaited(_openPicker());
  }

  Future<void> _openPicker() async {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    final now = DateTime.now();
    final first = widget.firstDate ?? DateTime(1900);
    final last = widget.lastDate ?? DateTime(2100);
    var initial = widget.initialDate ?? widget.value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      widget.onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: widget.enabled);
    final value = widget.value;
    final dateText = value != null
        ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
        : widget.hintText;

    final borderColor = switch (widget.tone) {
      VComponentTone.primary => dynamicColors.primary,
      VComponentTone.danger => dynamicColors.danger,
      _ => dynamicColors.borderDefault,
    };

    final borderWidth = VBorders.widthFor(widget.emphasis);
    final radius = BorderRadius.circular(VRadius.input);
    final fillColor = _highlighted
        ? dynamicColors.surfacePressed
        : dynamicColors.surface;

    // ignore: deprecated_member_use_from_same_package
    final legacyLabel = widget.label;
    // ignore: deprecated_member_use_from_same_package
    final legacyRequired = widget.required;

    final control = Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: isEnabled ? _handleTap : null,
        onHighlightChanged: isEnabled
            ? (highlighted) {
                if (_highlighted == highlighted) return;
                setState(() => _highlighted = highlighted);
              }
            : null,
        borderRadius: radius,
        child: Ink(
          height: context.vDensity.controlHeightMedium,
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space3),
          decoration: BoxDecoration(
            color: fillColor,
            border: VBorders.all(
              borderColor,
              width: borderWidth,
            ),
            borderRadius: radius,
          ),
          child: Row(
            children: [
              if (widget.iconPosition == VDatePickerIconPosition.left) ...[
                VIcon(
                  icon: VIcons.calendar,
                  size: 20,
                  color: dynamicColors.textMuted,
                ),
                const VGap(VSpacing.space2, axis: Axis.horizontal),
              ],
              Expanded(
                child: VText(
                  dateText,
                  variant: VTextVariant.bodyDefault,
                  color: value != null
                      ? dynamicColors.textPrimary
                      : dynamicColors.textMuted,
                ),
              ),
              if (widget.iconPosition == VDatePickerIconPosition.right) ...[
                const VGap(VSpacing.space2, axis: Axis.horizontal),
                VIcon(
                  icon: VIcons.calendar,
                  size: 20,
                  color: dynamicColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return vInspectorHide(
      Semantics(
        button: true,
        enabled: isEnabled,
        label: widget.semanticLabel ?? legacyLabel,
        child: vDisabledOpacity(
          enabled: isEnabled,
          child: vFieldShell(
            control: control,
            label: legacyLabel,
            isRequired: legacyRequired,
          ),
        ),
      ),
    );
  }
}
