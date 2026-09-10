import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/v_text_field.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_inspector_scope.dart';
import '../patterns/v_field.dart';
import '../tokens/v_duration.dart';
import 'validators/v_phone_validator.dart';

/// Phone input with a composed label/error shell and debounced validation.
/// Spaces are retained; invalid edits are rejected rather than sanitized.
/// Call [VPhoneValidator.validate] again when submitting a form.
class VPhoneField extends StatefulWidget {
  const VPhoneField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.validateOnChanged = true,
    this.debounceDuration = VDuration.normal,
    this.requiredMessage = VPhoneValidator.defaultRequiredMessage,
    this.invalidMessage = VPhoneValidator.defaultInvalidMessage,
    this.semanticLabel,
  }) : assert(
         controller == null || initialValue == null,
         'controller and initialValue cannot both supply text',
       );

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hintText;
  final String? helperText;

  /// A parent/server error takes precedence over built-in validation.
  final String? errorText;
  final bool isRequired;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool validateOnChanged;
  final Duration debounceDuration;
  final String requiredMessage;
  final String invalidMessage;
  final String? semanticLabel;

  @override
  State<VPhoneField> createState() => _VPhoneFieldState();
}

class _VPhoneFieldState extends State<VPhoneField> {
  static final _invalidCharacters = RegExp(r'[^0-9 ]');
  static final _formatter = TextInputFormatter.withFunction((oldValue, newValue) {
    return _invalidCharacters.hasMatch(newValue.text) ? oldValue : newValue;
  });

  late TextEditingController _controller;
  late String _lastText;
  Timer? _timer;
  String? _internalError;
  bool _hasValidated = false;

  String? _validate() => VPhoneValidator.validate(
    _controller.text,
    isRequired: widget.isRequired,
    requiredMessage: widget.requiredMessage,
    invalidMessage: widget.invalidMessage,
  );

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue ?? '');
    _lastText = _controller.text;
    _controller.addListener(_textChanged);
    if (widget.validateOnChanged && _lastText.isNotEmpty) {
      _hasValidated = true;
      _internalError = _validate();
    }
  }

  void _textChanged() {
    if (_controller.text == _lastText) return;
    _lastText = _controller.text;
    _timer?.cancel();
    if (!widget.validateOnChanged) return;
    _timer = Timer(widget.debounceDuration, () {
      if (!mounted) return;
      setState(() {
        _hasValidated = true;
        _internalError = _validate();
      });
    });
  }

  @override
  void didUpdateWidget(covariant VPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _timer?.cancel();
      final previousValue = _controller.value;
      _controller.removeListener(_textChanged);
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ??
          (widget.initialValue != null
              ? TextEditingController(text: widget.initialValue!)
              : TextEditingController.fromValue(previousValue));
      _lastText = _controller.text;
      _controller.addListener(_textChanged);
      _hasValidated = _hasValidated || _lastText.isNotEmpty;
      _internalError = widget.validateOnChanged && _hasValidated ? _validate() : null;
    } else if (widget.controller == null) {
      if (oldWidget.initialValue != widget.initialValue &&
          widget.initialValue != _controller.text) {
        final nextText = widget.initialValue ?? '';
        _controller.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        );
        _lastText = nextText;
        if (widget.validateOnChanged && _hasValidated) {
          _internalError = _validate();
        }
      }
    }
    if (oldWidget.validateOnChanged != widget.validateOnChanged ||
        oldWidget.isRequired != widget.isRequired ||
        oldWidget.requiredMessage != widget.requiredMessage ||
        oldWidget.invalidMessage != widget.invalidMessage) {
      _timer?.cancel();
      _internalError = widget.validateOnChanged && _hasValidated ? _validate() : null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_textChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText ?? _internalError;
    return vInspectorHide(
      VField(
        invalid: error != null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) VFieldLabel(widget.label!, isRequired: widget.isRequired),
            VTextField(
              controller: _controller,
              hintText: widget.hintText,
              enabled: widget.enabled,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              semanticLabel: widget.semanticLabel ?? widget.label,
              keyboardType: TextInputType.phone,
              inputFormatters: [_formatter],
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              tone: error != null ? VComponentTone.danger : VComponentTone.neutral,
            ),
            if (error != null)
              VFieldError(error)
            else if (widget.helperText != null)
              VFieldDescription(widget.helperText!),
          ],
        ),
      ),
    );
  }
}
