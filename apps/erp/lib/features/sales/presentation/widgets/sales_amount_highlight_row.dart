import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'package:erp/core/formatting/money_formatter.dart';
import 'sales_label_highlight_row.dart';

/// Hàng số tiền nổi bật dùng chung cho các màn Sales (SG-05 công nợ phát sinh,
/// SG-06 tổng đơn, …): nhận [amountMinor], format qua [MoneyFormatter], rồi
/// ủy quyền render cho [SalesLabelHighlightRow].
class SalesAmountHighlightRow extends StatelessWidget {
  const SalesAmountHighlightRow({
    super.key,
    required this.label,
    required this.amountMinor,
    this.tone = VComponentTone.primary,
    this.amountKey,
    this.labelVariant = VTextVariant.labelDefault,
    this.amountVariant = VTextVariant.labelDefaultMono,
    this.emphasizeLabel = true,
    this.padding = const EdgeInsets.all(VSpacing.space3),
    this.backgroundColor,
  });

  final String label;
  final int amountMinor;

  /// Quyết định nền tint + màu số tiền.
  final VComponentTone tone;

  /// Key cho `VText` số tiền (dùng trong widget test).
  final Key? amountKey;

  /// Typography nhãn bên trái (vd. `headingH4` khi số tiền dùng `headingH4Mono`).
  final VTextVariant labelVariant;

  /// Cho phép màn dùng cỡ chữ lớn hơn (vd. `headingH4Mono`).
  final VTextVariant amountVariant;

  /// `true`: nhãn cùng màu tone; `false`: nhãn dùng `textPrimary`.
  final bool emphasizeLabel;

  final EdgeInsetsGeometry padding;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SalesLabelHighlightRow(
      label: label,
      value: MoneyFormatter.formatMinor(amountMinor),
      tone: tone,
      valueKey: amountKey,
      labelVariant: labelVariant,
      valueVariant: amountVariant,
      emphasizeLabel: emphasizeLabel,
      padding: padding,
      backgroundColor: backgroundColor,
    );
  }
}
