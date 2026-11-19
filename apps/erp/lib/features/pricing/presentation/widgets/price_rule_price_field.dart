import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:c45_design_system/design_system.dart';

/// Ô nhập giá riêng — bọc [VMoneyField], xử lý selection tại feature layer.
///
/// Tránh crash `range.start > text.length` khi xóa hết số tiền mà không sửa DS.
/// Giới hạn nhập số tiền tối đa không vượt quá giới hạn int (2.147.483.647đ).
class PriceRulePriceField extends StatefulWidget {
  const PriceRulePriceField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.label = 'Giá riêng cho khách',
    this.isRequired = true,
    this.min = 1,
    this.max = 999999999999,
  });

  final TextEditingController controller;
  final ValueChanged<int?> onChanged;
  final String label;
  final bool isRequired;
  final int min;
  final int max;

  @override
  State<PriceRulePriceField> createState() => _PriceRulePriceFieldState();
}

class _PriceRulePriceFieldState extends State<PriceRulePriceField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_clampControllerSelection);
  }

  @override
  void didUpdateWidget(covariant PriceRulePriceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_clampControllerSelection);
      widget.controller.addListener(_clampControllerSelection);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_clampControllerSelection);
    super.dispose();
  }

  void _clampControllerSelection() {
    final value = widget.controller.value;
    final clamped = PriceRuleMoneySelectionClampFormatter.clamp(value);
    if (clamped != value) {
      widget.controller.value = clamped;
    }
  }

  static String _formatMax(int max) {
    return max.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return VMoneyField(
      label: widget.label,
      isRequired: widget.isRequired,
      controller: widget.controller,
      textAlign: TextAlign.start,
      suffixText: 'đ',
      onChanged: widget.onChanged,
      min: widget.min,
      max: widget.max,
      maxMessage: 'Giá nhập tối đa ${_formatMax(widget.max)}đ',
      textStyle: VTypography.monoNumeric,
      inputFormatters: [
        PriceRuleMoneyMaxFormatter(widget.max),
        const PriceRuleMoneySelectionClampFormatter(),
      ],
    );
  }
}

/// Formatter ngăn nhập số tiền lớn hơn [max].
class PriceRuleMoneyMaxFormatter extends TextInputFormatter {
  const PriceRuleMoneyMaxFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return newValue;
    }
    final parsed = int.tryParse(digitsOnly);
    if (parsed == null || parsed > max) {
      return oldValue;
    }
    return newValue;
  }
}

/// Clamp selection sau [VMoneyInputFormatter] — feature-local, không sửa DS.
class PriceRuleMoneySelectionClampFormatter extends TextInputFormatter {
  const PriceRuleMoneySelectionClampFormatter();

  static TextEditingValue clamp(TextEditingValue value) {
    final length = value.text.length;
    final base = value.selection.baseOffset.clamp(0, length);
    final extent = value.selection.extentOffset.clamp(0, length);
    if (base == value.selection.baseOffset &&
        extent == value.selection.extentOffset) {
      return value;
    }
    return value.copyWith(
      selection: TextSelection(baseOffset: base, extentOffset: extent),
      composing: TextRange.empty,
    );
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return clamp(newValue);
  }
}
