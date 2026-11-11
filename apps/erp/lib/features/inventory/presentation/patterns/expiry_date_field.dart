import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';

/// Ô nhập ngày hạn dùng / ngày sản xuất.
/// Tự nhận diện các định dạng dd/mm/yyyy, mm/yyyy, yyyy qua `LotDate.tryParseAuto`.
class InventoryExpiryField extends StatefulWidget {
  const InventoryExpiryField({
    super.key,
    required this.label,
    this.required = false,
    this.helper,
    required this.errorText,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool required;
  final String? helper;
  final String errorText;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<InventoryExpiryField> createState() => _InventoryExpiryFieldState();
}

class _InventoryExpiryFieldState extends State<InventoryExpiryField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant InventoryExpiryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.value.trim();
    final bool isInvalid =
        trimmed.isNotEmpty && LotDate.tryParseAuto(trimmed) == null;

    return VField(
      invalid: isInvalid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          VFieldLabel(
            widget.label,
            isRequired: widget.required,
          ),
          const SizedBox(height: VSpacing.space1),
          VTextField(
            controller: _controller,
            hintText: 'dd/mm/yyyy',
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            keyboardType: TextInputType.datetime,
            onChanged: (val) {
              widget.onChanged(val);
            },
          ),
          const SizedBox(height: VSpacing.space1),
          if (isInvalid)
            VFieldError(widget.errorText)
          else if (widget.helper != null)
            VFieldDescription(widget.helper!),
        ],
      ),
    );
  }
}

