import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../primitives/v_icon.dart';
import '../foundations/icons/v_icons.dart';

class VQuantitySelector extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final String? hintText;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState? state;
  final String? semanticLabel;

  const VQuantitySelector({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 9999,
    required this.onChanged,
    this.enabled = true,
    this.hintText,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state,
    this.semanticLabel,
  });

  @override
  State<VQuantitySelector> createState() => _VQuantitySelectorState();
}

class _VQuantitySelectorState extends State<VQuantitySelector> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value > 0 ? '${widget.value}' : '');
  }

  @override
  void didUpdateWidget(covariant VQuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final expectedText = widget.value > 0 ? '${widget.value}' : '';
    if (_controller.text != expectedText && !FocusScope.of(context).hasFocus) {
      _controller.text = expectedText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    if (_resolveState() != VComponentState.enabled) return;
    final currentValue = int.tryParse(_controller.text) ?? widget.min;
    if (currentValue < widget.max) {
      final newValue = currentValue + 1;
      _controller.text = '$newValue';
      widget.onChanged(newValue);
    }
  }

  void _decrement() {
    if (_resolveState() != VComponentState.enabled) return;
    final currentValue = int.tryParse(_controller.text) ?? widget.min;
    if (currentValue > widget.min) {
      final newValue = currentValue - 1;
      _controller.text = newValue > 0 ? '$newValue' : '';
      widget.onChanged(newValue);
    }
  }

  VComponentState _resolveState() {
    if (widget.state != null) return widget.state!;
    return widget.enabled ? VComponentState.enabled : VComponentState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final resolvedState = _resolveState();
    final isEnabled = resolvedState == VComponentState.enabled;

    final borderColor = switch (widget.tone) {
      VComponentTone.primary => colors.primary,
      VComponentTone.danger => colors.danger,
      _ => colors.borderStrong,
    };

    final borderWidth = widget.emphasis == VComponentEmphasis.strong
        ? VBorders.thick
        : VBorders.thin;
    final focusWidth = widget.emphasis == VComponentEmphasis.strong
        ? VBorders.thick
        : VBorders.medium;

    return Semantics(
      textField: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.hintText ?? 'Quantity',
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: _controller,
          enabled: isEnabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: VTypography.bodyDefault.copyWith(
            color: isEnabled ? colors.textPrimary : colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'SL trả',
            hintStyle: VTypography.bodyDefault.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.normal,
            ),
            contentPadding: const EdgeInsets.only(left: 12, right: 32, top: 10, bottom: 10),
            filled: true,
            fillColor: isEnabled ? colors.surface : colors.surfaceAlt,
            isDense: true,
            suffixIconConstraints: const BoxConstraints(
              maxWidth: 28,
              maxHeight: 44,
            ),
            border: VBorders.outlineInput(
              isEnabled ? borderColor : colors.borderDefault,
              width: borderWidth,
            ),
            enabledBorder: VBorders.outlineInput(
              isEnabled ? borderColor : colors.borderDefault,
              width: borderWidth,
            ),
            focusedBorder: VBorders.outlineInput(
              colors.primary,
              width: focusWidth,
            ),
            disabledBorder: VBorders.outlineInput(colors.borderDefault),
            errorBorder: VBorders.outlineInput(colors.danger),
            focusedErrorBorder: VBorders.outlineInput(
              colors.danger,
              width: VBorders.thick,
            ),
            suffixIcon: Container(
              width: 24,
              margin: const EdgeInsets.only(right: 4),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _increment,
                    behavior: HitTestBehavior.opaque,
                    child: VIcon(
                      icon: VIcons.chevronUp,
                      size: 16,
                      color: isEnabled ? colors.textSecondary : colors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: _decrement,
                    behavior: HitTestBehavior.opaque,
                    child: VIcon(
                      icon: VIcons.chevronDown,
                      size: 16,
                      color: isEnabled ? colors.textSecondary : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val) ?? 0;
            widget.onChanged(parsed);
          },
        ),
      ),
    );
  }
}
