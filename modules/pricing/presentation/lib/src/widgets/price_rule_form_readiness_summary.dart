import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../cubit/price_rule_form_state.dart';

/// D-05 SG-03 — Bảng so sánh giá riêng vs giá hiện tại / giá sàn.
class PriceRuleFormReadinessSummary extends StatelessWidget {
  const PriceRuleFormReadinessSummary({super.key, required this.form});

  final PriceRuleFormEditing form;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final price = form.rulePriceMinor;
    final list = form.listPriceMinor;
    final floor = form.floorPriceHidden ? null : form.floorPriceMinor;

    return VCard(
      backgroundColor: colors.successBg,
      border: Border.all(color: colors.success.withValues(alpha: 0.35)),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (list != null)
            _ComparisonRow(label: 'Giá hiện tại', value: _formatMinor(list)),
          if (floor != null)
            _ComparisonRow(label: 'Giá sàn', value: _formatMinor(floor)),
          if (price != null && list != null)
            _ComparisonRow(
              label: 'So với giá hiện tại',
              value: _formatDiffWithPercent(price - list, baseMinor: list),
              valueColor: price < list ? colors.danger : colors.success,
            ),
          if (price != null && floor != null)
            _ComparisonRow(
              label: 'So với giá sàn',
              value: _formatDiffWithPercent(price - floor, baseMinor: floor),
              valueColor: price < floor ? colors.danger : colors.success,
            ),
        ],
      ),
    );
  }

  String _formatMinor(int amountMinor) {
    return '${amountMinor.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
  }

  String _formatDiffWithPercent(int diffMinor, {required int baseMinor}) {
    final sign = diffMinor > 0 ? '+' : '';
    final diffLabel =
        '$sign${diffMinor.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
    if (baseMinor == 0) return diffLabel;
    final pct = (diffMinor / baseMinor) * 100;
    final pctLabel = pct.toStringAsFixed(1).replaceAll('.', ',');
    final pctSign = pct > 0 ? '+' : '';
    return '$diffLabel ($pctSign$pctLabel%)';
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space2),
      child: Row(
        children: [
          Expanded(
            child: VText(
              label,
              variant: VTextVariant.bodySmall,
              color: colors.textPrimary,
            ),
          ),
          VText(
            value,
            variant: VTextVariant.monoNumeric,
            color: valueColor ?? colors.textPrimary,
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}
