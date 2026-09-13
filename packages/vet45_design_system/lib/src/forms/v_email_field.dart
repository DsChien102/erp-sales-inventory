import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/v_text_field.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_inspector_scope.dart';
import '../tokens/v_duration.dart';
import 'validators/v_email_validator.dart';

class VEmailField extends StatefulWidget {
  const VEmailField({
    super.key,
    this.controller,
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
    this.suffixText,
    this.enabled,
    this.onChanged,
    @Deprecated('Use VFieldLabel(..., isRequired: true) instead') this.isRequired = false,
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.focusNode,
    this.onSubmitted,
    this.border = true,
    this.debounceDuration = VDuration.normal,
    this.validateOnChanged = true,
    this.invalidEmailMessage = VEmailValidator.defaultInvalidEmailMessage,
    this.requiredEmailMessage = VEmailValidator.defaultRequiredEmailMessage,
    this.minLength = VEmailValidator.defaultMinLength,
    this.maxLength = VEmailValidator.defaultMaxLength,
    this.minLengthEmailMessage,
    this.maxLengthEmailMessage,
    this.invalid,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  final TextEditingController? controller;
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
  final ValueChanged<String>? onChanged;
  @Deprecated('Use VFieldLabel(..., isRequired: true) instead')
  final bool isRequired;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool border;
  final Duration debounceDuration;
  final bool validateOnChanged;
  final String invalidEmailMessage;
  final String requiredEmailMessage;
  final int minLength;
  final int maxLength;
  final String? minLengthEmailMessage;
  final String? maxLengthEmailMessage;
  /// Local invalid override. Null inherits [VField.invalid].
  final bool? invalid;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

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
          // ignore: deprecated_member_use_from_same_package
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
    return vInspectorHide(
      VTextField(
        controller: widget.controller,
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
        keyboardType: TextInputType.emailAddress,
        onChanged: _handleChanged,
        // ignore: deprecated_member_use_from_same_package
        isRequired: widget.isRequired,
        inputFormatters: [
          LengthLimitingTextInputFormatter(widget.maxLength),
          ...?widget.inputFormatters,
        ],
        textStyle: widget.textStyle,
        textAlign: widget.textAlign,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        onSubmitted: widget.onSubmitted,
        border: widget.border,
        invalid: widget.invalid,
        tone: widget.tone,
        emphasis: widget.emphasis,
        semanticLabel: widget.semanticLabel,
      ),
    );
  }
}
