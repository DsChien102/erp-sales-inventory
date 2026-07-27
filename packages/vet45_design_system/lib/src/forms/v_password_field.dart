import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/v_text_field.dart';
import '../foundation/v_component_contracts.dart';
import '../tokens/v_duration.dart';
import 'validators/v_password_validator.dart';

class VPasswordField extends StatefulWidget {
  const VPasswordField({
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
    this.initiallyObscured = true,
    this.requiredPasswordMessage =
        VPasswordValidator.defaultRequiredPasswordMessage,
    this.minLength = VPasswordValidator.defaultMinLength,
    this.maxLength = VPasswordValidator.defaultMaxLength,
    this.minLengthPasswordMessage,
    this.maxLengthPasswordMessage,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state = VComponentState.enabled,
    this.semanticLabel,
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
  final bool initiallyObscured;
  final String requiredPasswordMessage;
  final int minLength;
  final int maxLength;
  final String? minLengthPasswordMessage;
  final String? maxLengthPasswordMessage;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState state;
  final String? semanticLabel;

  @override
  State<VPasswordField> createState() => _VPasswordFieldState();
}

class _VPasswordFieldState extends State<VPasswordField> {
  Timer? _debounceTimer;
  String? _internalError;
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.initiallyObscured;
  }

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
        _internalError = VPasswordValidator.validate(
          value,
          isRequired: widget.isRequired,
          minLength: widget.minLength,
          maxLength: widget.maxLength,
          requiredPasswordMessage: widget.requiredPasswordMessage,
          minLengthPasswordMessage: widget.minLengthPasswordMessage,
          maxLengthPasswordMessage: widget.maxLengthPasswordMessage,
        );
      });
    });
  }

  void _toggleObscured() {
    setState(() => _obscured = !_obscured);
  }

  Widget? get _resolvedSuffixIcon {
    if (widget.suffixIcon != null) return widget.suffixIcon;
    final isEnabled =
        widget.enabled && widget.state != VComponentState.disabled;
    return IconButton(
      onPressed: isEnabled ? _toggleObscured : null,
      icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
      tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
    );
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
      suffixIcon: _resolvedSuffixIcon,
      suffixIconConstraints: widget.suffixIconConstraints,
      suffixText: widget.suffixText,
      enabled: widget.enabled,
      obscureText: _obscured,
      keyboardType: TextInputType.visiblePassword,
      onChanged: _handleChanged,
      isRequired: widget.isRequired,
      maxLines: 1,
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
      tone: widget.tone,
      emphasis: widget.emphasis,
      state: (widget.errorText ?? _internalError) != null
          ? VComponentState.error
          : (widget.enabled ? widget.state : VComponentState.disabled),
      semanticLabel: widget.semanticLabel,
    );
  }
}
