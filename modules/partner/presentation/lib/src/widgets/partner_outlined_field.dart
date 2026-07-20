import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_design_system/design_system.dart';

/// Floating-label text field for partner create/edit — wraps [VTextField].
class PartnerOutlinedTextField extends StatefulWidget {
  const PartnerOutlinedTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.isRequired = false,
    this.errorText,
    this.hintText,
    this.keyboardType,
    this.digitsOnly = false,
    this.onChanged,
  });

  final String label;
  final String? initialValue;
  final bool isRequired;
  final String? errorText;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool digitsOnly;
  final ValueChanged<String>? onChanged;

  @override
  State<PartnerOutlinedTextField> createState() => _PartnerOutlinedTextFieldState();
}

class _PartnerOutlinedTextFieldState extends State<PartnerOutlinedTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant PartnerOutlinedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialValue ?? '';
    if (oldWidget.initialValue != widget.initialValue && _controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
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
    return VTextField(
      controller: _controller,
      label: widget.label,
      isRequired: widget.isRequired,
      errorText: widget.errorText,
      hintText: widget.hintText,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.digitsOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      onChanged: widget.onChanged,
    );
  }
}

/// Multiline outlined field — wraps [VTextField].
class PartnerOutlinedMultilineTextField extends StatefulWidget {
  const PartnerOutlinedMultilineTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.isRequired = false,
    this.errorText,
    this.hintText,
    this.minLines = 3,
    this.maxLines = 5,
    this.onChanged,
  });

  final String label;
  final String? initialValue;
  final bool isRequired;
  final String? errorText;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<PartnerOutlinedMultilineTextField> createState() =>
      _PartnerOutlinedMultilineTextFieldState();
}

class _PartnerOutlinedMultilineTextFieldState
    extends State<PartnerOutlinedMultilineTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant PartnerOutlinedMultilineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialValue ?? '';
    if (oldWidget.initialValue != widget.initialValue && _controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
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
    return VTextField(
      controller: _controller,
      label: widget.label,
      isRequired: widget.isRequired,
      errorText: widget.errorText,
      hintText: widget.hintText,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
    );
  }
}

/// Outlined select — wraps [VSelect].
class PartnerOutlinedDropdown<T> extends StatelessWidget {
  const PartnerOutlinedDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.isRequired = false,
    this.errorText,
    this.hintText,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final String? errorText;
  final String? hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return VSelect<T>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      isRequired: isRequired,
      errorText: errorText,
      hintText: hintText,
      enabled: enabled,
    );
  }
}
