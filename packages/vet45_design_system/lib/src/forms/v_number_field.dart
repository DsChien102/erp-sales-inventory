import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/v_text_field.dart';
import '../tokens/v_duration.dart';
import 'formatters/v_number_input_formatter.dart';
import 'validators/v_number_validator.dart';

class VNumberField extends StatefulWidget {
  const VNumberField({
    super.key,
    this.controller,
    this.value,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.suffixText,
    this.enabled = true,
    this.onChanged,
    this.isRequired = false,
    this.allowDecimal = false,
    this.allowNegative = false,
    this.decimalPlaces = 2,
    this.min,
    this.max,
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.focusNode,
    this.onSubmitted,
    this.contentPadding,
    this.fillColor,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.variant = VTextFieldVariant.standard,
    this.debounceDuration = VDuration.normal,
    this.requiredMessage = VNumberValidator.defaultRequiredMessage,
    this.invalidMessage = VNumberValidator.defaultInvalidMessage,
    this.minMessage,
    this.maxMessage,
  });

  final TextEditingController? controller;
  final num? value;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final String? suffixText;
  final bool enabled;
  final ValueChanged<num?>? onChanged;
  final bool isRequired;
  final bool allowDecimal;
  final bool allowNegative;
  final int decimalPlaces;
  final num? min;
  final num? max;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final VTextFieldVariant variant;
  final Duration debounceDuration;
  final String requiredMessage;
  final String invalidMessage;
  final String? minMessage;
  final String? maxMessage;

  @override
  State<VNumberField> createState() => _VNumberFieldState();
}

class _VNumberFieldState extends State<VNumberField> {
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
  void didUpdateWidget(covariant VNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final currentParsed = VNumberValidator.parse(
        _controller.text,
        allowDecimal: widget.allowDecimal,
      );
      if (widget.value != currentParsed && !(widget.focusNode?.hasFocus ?? false)) {
        _controller.text = _formatValue(widget.value);
      }
    }
  }

  String _formatValue(num? value) {
    if (value == null) {
      return '';
    }
    return VNumberValidator.format(
      value,
      allowDecimal: widget.allowDecimal,
      decimalPlaces: widget.decimalPlaces,
    );
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
    final parsed = VNumberValidator.parse(
      displayValue,
      allowDecimal: widget.allowDecimal,
    );
    widget.onChanged?.call(parsed);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (!mounted) return;
      setState(() {
        _internalError = VNumberValidator.validate(
          displayValue,
          isRequired: widget.isRequired,
          allowDecimal: widget.allowDecimal,
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
    return VTextField(
      controller: _controller,
      label: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText ?? _internalError,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      suffixIconConstraints: widget.suffixIconConstraints,
      suffixText: widget.suffixText,
      enabled: widget.enabled,
      keyboardType: widget.allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      onChanged: _handleChanged,
      isRequired: widget.isRequired,
      inputFormatters: [
        VNumberInputFormatter(
          allowDecimal: widget.allowDecimal,
          allowNegative: widget.allowNegative,
          decimalPlaces: widget.decimalPlaces,
        ),
        ...?widget.inputFormatters,
      ],
      textStyle: widget.textStyle,
      textAlign: widget.textAlign,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onSubmitted: widget.onSubmitted,
      contentPadding: widget.contentPadding,
      fillColor: widget.fillColor,
      border: widget.border,
      enabledBorder: widget.enabledBorder,
      focusedBorder: widget.focusedBorder,
      variant: widget.variant,
    );
  }
}
