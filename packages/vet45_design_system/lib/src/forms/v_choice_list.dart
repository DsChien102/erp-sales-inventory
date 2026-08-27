import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_inspector_scope.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'models/v_choice_option.dart';
import 'validators/v_choice_list_validator.dart';
import 'widgets/v_choice_list_tile.dart';

class VChoiceList<T> extends StatefulWidget {
  const VChoiceList({
    super.key,
    this.title,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.allowMultiple = false,
    this.enabled,
    this.titleHidden = false,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.minSelections,
    this.maxSelections,
    this.requiredMessage = VChoiceListValidator.defaultRequiredMessage,
    this.minSelectionsMessage,
    this.maxSelectionsMessage,
    this.semanticLabel,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
  });

  final String? title;
  final List<VChoiceOption<T>> choices;
  final List<T> selected;
  final ValueChanged<List<T>>? onChanged;
  final bool allowMultiple;
  final bool? enabled;
  final bool titleHidden;
  final String? helperText;
  final String? errorText;
  final bool isRequired;
  final int? minSelections;
  final int? maxSelections;
  final String requiredMessage;
  final String? minSelectionsMessage;
  final String? maxSelectionsMessage;
  final String? semanticLabel;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;

  @override
  State<VChoiceList<T>> createState() => _VChoiceListState<T>();
}

class _VChoiceListState<T> extends State<VChoiceList<T>> {
  String? _internalError;

  String? get _effectiveError => widget.errorText ?? _internalError;

  bool _isSelected(T value) => widget.selected.contains(value);

  T? get _groupValue => widget.allowMultiple || widget.selected.isEmpty
      ? null
      : widget.selected.first;

  void _handleChoiceChanged(VChoiceOption<T> option, bool checked) {
    final updated = VChoiceListValidator.updateSelected(
      option.value,
      checked,
      widget.selected,
      allowMultiple: widget.allowMultiple,
    );

    widget.onChanged?.call(updated);
    setState(() {
      _internalError = VChoiceListValidator.validate(
        updated,
        isRequired: widget.isRequired,
        minSelections: widget.minSelections,
        maxSelections: widget.maxSelections,
        requiredMessage: widget.requiredMessage,
        minSelectionsMessage: widget.minSelectionsMessage,
        maxSelectionsMessage: widget.maxSelectionsMessage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: widget.enabled);
    final hasError = _effectiveError != null;
    final showTitle = widget.title != null && !widget.titleHidden;

    return vInspectorHide(
      Semantics(
        label: widget.semanticLabel ?? widget.title ?? 'Choice list',
        enabled: isEnabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle) ...[
              RichText(
                text: TextSpan(
                  style: VTypography.headingH4.copyWith(
                    color: isEnabled ? dynamicColors.textPrimary : dynamicColors.textMuted,
                  ),
                  children: [
                    TextSpan(text: widget.title!),
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
            _buildChoices(hasError, isEnabled),
            if (_effectiveError != null) ...[
              Text(
                _effectiveError!,
                style: VTypography.bodySmall.copyWith(color: dynamicColors.danger),
              ),
            ] else if (widget.helperText != null) ...[
              Text(
                widget.helperText!,
                style: VTypography.bodySmall.copyWith(
                  color: dynamicColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChoices(bool hasError, bool isEnabled) {
    final tiles = widget.choices.map((option) {
      final isSelected = _isSelected(option.value);
      return Padding(
        padding: const EdgeInsets.only(bottom: VSpacing.space3),
        child: VChoiceListTile<T>(
          option: option,
          isSelected: isSelected,
          allowMultiple: widget.allowMultiple,
          enabled: isEnabled,
          hasError: hasError,
          onChanged: (checked) => _handleChoiceChanged(option, checked),
        ),
      );
    }).toList();

    if (widget.allowMultiple) {
      return Column(children: tiles);
    }

    return RadioGroup<T>(
      groupValue: _groupValue,
      onChanged: isEnabled
          ? (value) {
              if (value == null) {
                widget.onChanged?.call([]);
                setState(() {
                  _internalError = VChoiceListValidator.validate(
                    [],
                    isRequired: widget.isRequired,
                    minSelections: widget.minSelections,
                    maxSelections: widget.maxSelections,
                    requiredMessage: widget.requiredMessage,
                    minSelectionsMessage: widget.minSelectionsMessage,
                    maxSelectionsMessage: widget.maxSelectionsMessage,
                  );
                });
                return;
              }

              final option = widget.choices.firstWhere(
                (choice) => choice.value == value,
              );
              _handleChoiceChanged(option, true);
            }
          : (_) {},
      child: Column(children: tiles),
    );
  }
}
