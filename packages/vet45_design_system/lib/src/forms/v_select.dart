import 'package:flutter/material.dart';

import '../components/v_dropdown.dart';
import '../components/v_searchable_dropdown.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../primitives/v_text.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'validators/v_select_validator.dart';

class VSelect<T> extends StatefulWidget {
  const VSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hintText = 'Chọn...',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.isRequired = false,
    this.searchable = false,
    this.requiredMessage = VSelectValidator.defaultRequiredMessage,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state = VComponentState.enabled,
    this.semanticLabel,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool isRequired;
  final bool searchable;
  final String requiredMessage;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState state;
  final String? semanticLabel;

  @override
  State<VSelect<T>> createState() => _VSelectState<T>();
}

class _VSelectState<T> extends State<VSelect<T>> {
  String? _internalError;

  String? get _effectiveError => widget.errorText ?? _internalError;

  void _handleChanged(T? newValue) {
    widget.onChanged?.call(newValue);
    setState(() {
      _internalError = VSelectValidator.validate(
        newValue,
        isRequired: widget.isRequired,
        requiredMessage: widget.requiredMessage,
      );
    });
  }

  VComponentTone get _dropdownTone {
    if (_effectiveError != null) {
      return VComponentTone.danger;
    }
    return widget.tone;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isEnabled = widget.enabled && widget.state != VComponentState.disabled;
    final dropdownState = _effectiveError != null
        ? VComponentState.error
        : (isEnabled ? widget.state : VComponentState.disabled);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.label!,
                    style: VTypography.headingH4.copyWith(
                      color: dynamicColors.textPrimary,
                    ),
                  ),
                if (widget.isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: dynamicColors.danger),
                  ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space2),
        ],
        if (widget.searchable)
          VSearchableDropdown<T>(
            value: widget.value,
            items: _toMenuEntries(widget.items),
            onChanged: _handleChanged,
            enabled: isEnabled,
            hintText: widget.hintText,
            tone: _dropdownTone,
            emphasis: widget.emphasis,
            state: dropdownState,
            semanticLabel: widget.semanticLabel,
          )
        else
          VDropdown<T>(
            value: widget.value,
            items: widget.items,
            onChanged: _handleChanged,
            enabled: isEnabled,
            hintText: widget.hintText,
            tone: _dropdownTone,
            emphasis: widget.emphasis,
            state: dropdownState,
            semanticLabel: widget.semanticLabel,
          ),
        if (_effectiveError != null) ...[
          const SizedBox(height: VSpacing.space1),
          Text(
            _effectiveError!,
            style: VTypography.bodySmall.copyWith(color: dynamicColors.danger),
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: VSpacing.space1),
          Text(
            widget.helperText!,
            style: VTypography.bodySmall.copyWith(
              color: dynamicColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  List<DropdownMenuEntry<T>> _toMenuEntries(List<DropdownMenuItem<T>> items) {
    return items
        .where((item) => item.value != null)
        .map(
          (item) => DropdownMenuEntry<T>(
            value: item.value as T,
            label: _extractLabel(item.child),
          ),
        )
        .toList();
  }

  String _extractLabel(Widget child) {
    if (child is Text) {
      return child.data ?? child.textSpan?.toPlainText() ?? '';
    }
    if (child is VText) {
      return child.data;
    }
    if (child is DefaultTextStyle) {
      return _extractLabel(child.child);
    }
    return child.toString();
  }
}
