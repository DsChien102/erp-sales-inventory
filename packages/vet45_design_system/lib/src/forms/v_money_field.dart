import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/v_text_field.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_inspector_scope.dart';
import '../tokens/v_duration.dart';
import 'formatters/v_money_input_formatter.dart';
import 'validators/v_money_validator.dart';

class VMoneyField extends StatefulWidget {
  const VMoneyField({
    super.key,
    this.controller,
    this.value,
    @Deprecated('Use VField + VFieldLabel instead') this.label,
    this.hintText,
    @Deprecated('Use VFieldDescription instead') this.helperText,
    @Deprecated(
      'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
    )
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.suffixText = 'đ',
    this.enabled,
    this.onChanged,
    @Deprecated('Use VFieldLabel(..., isRequired: true) instead') this.isRequired = false,
    this.min,
    this.max,
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.end,
    this.autofocus = false,
    this.focusNode,
    this.onSubmitted,
    this.border = true,
    this.debounceDuration = VDuration.normal,
    this.requiredMessage = VMoneyValidator.defaultRequiredMessage,
    this.invalidMessage = VMoneyValidator.defaultInvalidMessage,
    this.minMessage,
    this.maxMessage,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final int? value;
  @Deprecated('Use VField + VFieldLabel instead')
  final String? label;
  final String? hintText;
  @Deprecated('Use VFieldDescription instead')
  final String? helperText;
  @Deprecated(
    'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
  )
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final String? suffixText;
  final bool? enabled;
  final ValueChanged<int?>? onChanged;
  @Deprecated('Use VFieldLabel(..., isRequired: true) instead')
  final bool isRequired;
  final int? min;
  final int? max;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool border;
  final Duration debounceDuration;
  final String requiredMessage;
  final String invalidMessage;
  final String? minMessage;
  final String? maxMessage;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  @override
  State<VMoneyField> createState() => _VMoneyFieldState();
}

class _VMoneyFieldState extends State<VMoneyField> {
  Timer? _debounceTimer;
  String? _internalError;
  late TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownsController = true;
      _controller = TextEditingController(text: _formatValue(widget.value));
    }
  }

  @override
  void didUpdateWidget(covariant VMoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != VMoneyValidator.parse(_controller.text)) {
      final formatted = _formatValue(widget.value);
      if (_controller.text != formatted && !(_focusNode?.hasFocus ?? false)) {
        _controller.text = formatted;
      }
    }
  }

  FocusNode? get _focusNode => widget.focusNode;

  String _formatValue(int? value) {
    if (value == null) {
      return '';
    }
    return VMoneyValidator.format(value);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleChanged(String displayValue) {
    final parsed = VMoneyValidator.parse(displayValue);
    widget.onChanged?.call(parsed);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (!mounted) return;
      setState(() {
        _internalError = VMoneyValidator.validate(
          displayValue,
          // ignore: deprecated_member_use_from_same_package
          isRequired: widget.isRequired,
          min: widget.min,
          max: widget.max,
          requiredMessage: widget.requiredMessage,
          invalidMessage: widget.invalidMessage,
          minMessage: widget.minMessage,
          maxMessage: widget.maxMessage,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return vInspectorHide(
      VTextField(
        controller: _controller,
        // ignore: deprecated_member_use_from_same_package
        label: widget.label,
        hintText: widget.hintText,
        // ignore: deprecated_member_use_from_same_package
        helperText: widget.helperText,
        // ignore: deprecated_member_use_from_same_package
        errorText: widget.errorText ?? _internalError,
        prefixIcon:
            widget.prefixIcon != null ? vInspectorShow(widget.prefixIcon!) : null,
        suffixIcon:
            widget.suffixIcon != null ? vInspectorShow(widget.suffixIcon!) : null,
        suffixIconConstraints: widget.suffixIconConstraints,
        suffixText: widget.suffixText,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        onChanged: _handleChanged,
        // ignore: deprecated_member_use_from_same_package
        isRequired: widget.isRequired,
        inputFormatters: [
          const VMoneyInputFormatter(),
          ...?widget.inputFormatters,
        ],
        textStyle: widget.textStyle,
        textAlign: widget.textAlign,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        onSubmitted: widget.onSubmitted,
        border: widget.border,
        tone: widget.tone,
        emphasis: widget.emphasis,
        semanticLabel: widget.semanticLabel,
      ),
    );
  }
}
