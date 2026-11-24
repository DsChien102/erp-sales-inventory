import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:c45_design_system/design_system.dart';

class PartnerTransformLabeledTextField extends StatefulWidget {
  const PartnerTransformLabeledTextField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.labelKey,
    this.isRequired = false,
    this.keyboardType,
    this.digitsOnly = false,
    this.inputFormatters,
    this.isEmail = false,
    this.emailValidateOnChanged = true,
    this.isPhone = false,
    this.hintText,
    this.errorText,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final Key? labelKey;
  final bool isRequired;
  final TextInputType? keyboardType;
  final bool digitsOnly;

  /// Custom formatters; takes precedence over [digitsOnly] when non-null.
  final List<TextInputFormatter>? inputFormatters;
  final bool isEmail;
  final bool emailValidateOnChanged;
  final bool isPhone;
  final String? hintText;
  final String? errorText;

  @override
  State<PartnerTransformLabeledTextField> createState() =>
      _PartnerTransformLabeledTextFieldState();
}

class _PartnerTransformLabeledTextFieldState
    extends State<PartnerTransformLabeledTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant PartnerTransformLabeledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // VPhoneField still owns its own label/error chrome (not deprecated yet).
    if (widget.isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PartnerTransformFieldLabel(
            key: widget.labelKey,
            label: widget.label,
            isRequired: widget.isRequired,
          ),
          const VGap.sm(),
          VPhoneField(
            controller: _controller,
            hintText: widget.hintText,
            errorText: widget.errorText,
            onChanged: widget.onChanged,
            validateOnChanged: false,
          ),
        ],
      );
    }

    return VField(
      invalid: hasError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PartnerTransformFieldLabel(
            key: widget.labelKey,
            label: widget.label,
            isRequired: widget.isRequired,
          ),
          const VGap.sm(),
          if (widget.isEmail)
            VEmailField(
              controller: _controller,
              hintText: widget.hintText,
              onChanged: widget.onChanged,
              validateOnChanged: widget.emailValidateOnChanged,
            )
          else
            VTextField(
              controller: _controller,
              keyboardType: widget.keyboardType,
              hintText: widget.hintText,
              onChanged: widget.onChanged,
              inputFormatters: widget.inputFormatters ??
                  (widget.digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null),
            ),
          if (hasError) VFieldError(widget.errorText!),
        ],
      ),
    );
  }
}

class PartnerTransformLabeledDropdown<T> extends StatelessWidget {
  const PartnerTransformLabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelKey,
    this.isRequired = false,
    this.hintText,
    this.errorText,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Key? labelKey;
  final bool isRequired;
  final String? hintText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return VField(
      invalid: hasError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PartnerTransformFieldLabel(
            key: labelKey,
            label: label,
            isRequired: isRequired,
          ),
          const VGap.sm(),
          VSelect<T>(
            value: value,
            items: items,
            hintText: hintText ?? 'Chọn...',
            tone: hasError ? VComponentTone.danger : VComponentTone.neutral,
            onChanged: onChanged,
          ),
          if (hasError) VFieldError(errorText!),
        ],
      ),
    );
  }
}

class PartnerTransformFieldLabel extends StatelessWidget {
  const PartnerTransformFieldLabel({
    super.key,
    required this.label,
    this.isRequired = false,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return RichText(
      text: TextSpan(
        style: VTypography.bodySmall.copyWith(
          color: colors.textSecondary,
          fontSize: 13,
          height: 1.2,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(color: colors.danger),
            ),
        ],
      ),
    );
  }
}
