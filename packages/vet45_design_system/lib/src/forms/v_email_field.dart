import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/v_text_field.dart';
import '../tokens/v_duration.dart';
import 'validators/v_email_validator.dart';

class VEmailField extends StatefulWidget {
  const VEmailField({
    super.key,
    this.controller,
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
    this.minLines,
    this.maxLines = 1,
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
    this.validateOnChanged = true,
    this.invalidEmailMessage = VEmailValidator.defaultInvalidEmailMessage,
    this.requiredEmailMessage = VEmailValidator.defaultRequiredEmailMessage,
    this.minLength = VEmailValidator.defaultMinLength,
    this.maxLength = VEmailValidator.defaultMaxLength,
    this.minLengthEmailMessage,
    this.maxLengthEmailMessage,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final String? suffixText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final bool isRequired;
  final int? minLines;
  final int? maxLines;
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
  final bool validateOnChanged;
  final String invalidEmailMessage;
  final String requiredEmailMessage;
  final int minLength;
  final int maxLength;
  final String? minLengthEmailMessage;
  final String? maxLengthEmailMessage;

  @override
  State<VEmailField> createState() => _VEmailFieldState();
}

class _VEmailFieldState extends State<VEmailField> {
  Timer? _debounceTimer;
  String? _internalError;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    _debounceTimer?.cancel();
    if (!widget.validateOnChanged) return;
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (!mounted) return;
      setState(() {
        _internalError = VEmailValidator.validate(
          value,
          isRequired: widget.isRequired,
          minLength: widget.minLength,
          maxLength: widget.maxLength,
          invalidEmailMessage: widget.invalidEmailMessage,
          requiredEmailMessage: widget.requiredEmailMessage,
          minLengthEmailMessage: widget.minLengthEmailMessage,
          maxLengthEmailMessage: widget.maxLengthEmailMessage,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return VTextField(
      controller: widget.controller,
      label: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText ?? _internalError,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      suffixIconConstraints: widget.suffixIconConstraints,
      suffixText: widget.suffixText,
      enabled: widget.enabled,
      keyboardType: TextInputType.emailAddress,
      onChanged: _handleChanged,
      isRequired: widget.isRequired,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      inputFormatters: [
        LengthLimitingTextInputFormatter(widget.maxLength),
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
