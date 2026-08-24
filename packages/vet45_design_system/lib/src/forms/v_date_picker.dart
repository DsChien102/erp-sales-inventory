import 'dart:async';

import 'package:flutter/material.dart';

import '../components/v_text_field.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';

class VDatePicker extends StatefulWidget {
  final DateTime? value;
  final String label;
  final String hintText;
  final bool required;
  final ValueChanged<DateTime>? onChanged;

  /// When set, skips the built-in [showDatePicker] and runs this instead
  /// (e.g. custom clear / pick flows).
  final VoidCallback? onTap;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final bool enabled;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState? state;
  final String? semanticLabel;

  const VDatePicker({
    super.key,
    this.value,
    required this.label,
    this.hintText = 'Chọn ngày',
    this.required = false,
    this.onChanged,
    this.onTap,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.enabled = true,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state,
    this.semanticLabel,
  });

  @override
  State<VDatePicker> createState() => _VDatePickerState();
}

class _VDatePickerState extends State<VDatePicker> {
  bool _highlighted = false;

  VComponentState _resolveState() {
    if (widget.state != null) return widget.state!;
    if (!widget.enabled) return VComponentState.disabled;
    return VComponentState.enabled;
  }

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
    final resolvedState = _resolveState();
    final isEnabled = resolvedState == VComponentState.enabled;
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
    final fillColor = !isEnabled
        ? dynamicColors.surfaceAlt
        : _highlighted
        ? dynamicColors.surfacePressed
        : dynamicColors.surface;

    return vInspectorHide(
      Semantics(
        button: true,
        enabled: isEnabled,
        label: widget.semanticLabel ?? widget.label,
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
                const VGap.sm(),
                VText(
                  widget.label,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  color: dynamicColors.textPrimary,
                ),
                if (widget.required) ...[
                  const VGap.xs(),
                  VText(
                    '*',
                    variant: VTextVariant.bodyDefault,
                    color: dynamicColors.danger,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            const VGap.sm(),
            Material(
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
                  height: VTextField.controlHeight,
                  padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                  decoration: BoxDecoration(
                    color: fillColor,
                    border: VBorders.all(
                      isEnabled ? borderColor : dynamicColors.borderDefault,
                      width: borderWidth,
                    ),
                    borderRadius: radius,
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
                        color: dynamicColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
