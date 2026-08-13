import 'dart:async';

import 'package:flutter/material.dart';

import '../components/v_text_field.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';

class VDatePicker extends StatelessWidget {
  /// Lets [InkWell] splash confirm/fade before [showDatePicker] pushes a route
  /// (which otherwise cancels the Material ink mid-animation).
  static const Duration _inkSplashSettle = Duration(milliseconds: 220);

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

  VComponentState _resolveState() {
    if (state != null) return state!;
    if (!enabled) return VComponentState.disabled;
    return VComponentState.enabled;
  }

  void _handleTap(BuildContext context) {
    // Keep this sync — do not await in the InkWell gesture callback.
    unawaited(
      Future<void>.delayed(_inkSplashSettle, () async {
        if (!context.mounted) return;
        await _openPicker(context);
      }),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    if (onTap != null) {
      onTap!();
      return;
    }

    final now = DateTime.now();
    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? DateTime(2100);
    var initial = initialDate ?? value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      onChanged?.call(picked);
    }
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

    final borderWidth = VBorders.widthFor(emphasis);
    final radius = BorderRadius.circular(VRadius.input);
    final fillColor = !isEnabled ? dynamicColors.surfaceAlt : dynamicColors.surface;

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
              const VGap.sm(),
              VText(
                label,
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.w600),
                color: dynamicColors.textPrimary,
              ),
              if (required) ...[
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
              onTap: isEnabled ? () => _handleTap(context) : null,
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
    );
  }
}
