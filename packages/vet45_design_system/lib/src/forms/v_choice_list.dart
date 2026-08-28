import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_inspector_scope.dart';
import '../patterns/v_field.dart';
import '../tokens/v_spacing.dart';
import 'models/v_choice_option.dart';
import 'validators/v_choice_list_validator.dart';
import 'widgets/v_choice_list_tile.dart';

class VChoiceList<T> extends StatefulWidget {
  const VChoiceList({
    super.key,
    @Deprecated('Use VField + VFieldLabel instead') this.title,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.allowMultiple = false,
    this.enabled,
    this.titleHidden = false,
    @Deprecated('Use VFieldDescription instead') this.helperText,
    @Deprecated(
      'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
    )
    this.errorText,
    @Deprecated('Use VFieldLabel(..., isRequired: true) instead') this.isRequired = false,
    this.minSelections,
    this.maxSelections,
    this.requiredMessage = VChoiceListValidator.defaultRequiredMessage,
    this.minSelectionsMessage,
    this.maxSelectionsMessage,
    this.semanticLabel,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
  });

  @Deprecated('Use VField + VFieldLabel instead')
  final String? title;
  final List<VChoiceOption<T>> choices;
  final List<T> selected;
  final ValueChanged<List<T>>? onChanged;
  final bool allowMultiple;
  final bool? enabled;
  final bool titleHidden;
  @Deprecated('Use VFieldDescription instead')
  final String? helperText;
  @Deprecated(
    'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
  )
  final String? errorText;
  @Deprecated('Use VFieldLabel(..., isRequired: true) instead')
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

  // ignore: deprecated_member_use_from_same_package
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
        // ignore: deprecated_member_use_from_same_package
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
    final isEnabled = VComponentScope.resolveEnabled(context, local: widget.enabled);
    final hasError = _effectiveError != null;
    // ignore: deprecated_member_use_from_same_package
    final legacyTitle = widget.title;
    // ignore: deprecated_member_use_from_same_package
    final legacyHelper = widget.helperText;
    // ignore: deprecated_member_use_from_same_package
    final legacyRequired = widget.isRequired;
    final showTitle = legacyTitle != null && !widget.titleHidden;
    final shellLabel = showTitle ? legacyTitle : null;

    final control = _buildChoices(hasError, isEnabled);
    final useShell = shellLabel != null ||
        legacyHelper != null ||
        _effectiveError != null ||
        (legacyRequired && showTitle);
    final body = useShell
        ? vFieldShell(
            control: control,
            label: shellLabel,
            isRequired: legacyRequired && showTitle,
            helperText: legacyHelper,
            errorText: _effectiveError,
          )
        : control;

    return vInspectorHide(
      Semantics(
        label: widget.semanticLabel ?? legacyTitle ?? 'Choice list',
        enabled: isEnabled,
        child: body,
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
                    // ignore: deprecated_member_use_from_same_package
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
