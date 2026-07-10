import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerTransformLabeledTextField extends StatefulWidget {
  const PartnerTransformLabeledTextField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.labelKey,
    this.isRequired = false,
    this.keyboardType,
    this.hintText,
    this.errorText,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final Key? labelKey;
  final bool isRequired;
  final TextInputType? keyboardType;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartnerTransformFieldLabel(
          key: widget.labelKey,
          label: widget.label,
          isRequired: widget.isRequired,
        ),
        const SizedBox(height: 6),
        VTextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          hintText: widget.hintText,
          errorText: widget.errorText,
          onChanged: widget.onChanged,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space3,
            vertical: 10,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartnerTransformFieldLabel(
          key: labelKey,
          label: label,
          isRequired: isRequired,
        ),
        const SizedBox(height: 6),
        VDropdown<T>(
          value: value,
          items: items,
          hintText: hintText ?? 'Chọn...',
          tone: hasError ? VComponentTone.danger : VComponentTone.neutral,
          onChanged: onChanged,
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: VTypography.bodySmall.copyWith(color: VColors.danger),
          ),
        ],
      ],
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
    return RichText(
      text: TextSpan(
        style: VTypography.bodySmall.copyWith(
          color: context.vColors.textSecondary,
          fontSize: 13,
          height: 1.2,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: VColors.danger),
            ),
        ],
      ),
    );
  }
}
