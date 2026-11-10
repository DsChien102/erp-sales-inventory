import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class StockCostBlock extends StatelessWidget {
  final StockCost cost;
  final String uom;

  const StockCostBlock({
    super.key,
    required this.cost,
    required this.uom,
  });

  String _formatUnitCost(num? value) {
    if (value == null) return 'Chưa công bố';
    return '${MoneyFormatter.formatMinor(value.round())}/$uom';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final officialText = cost.provisional || cost.officialUnitCost == null
        ? 'Chưa công bố'
        : _formatUnitCost(cost.officialUnitCost);
    final movingText = cost.movingAvgCost == null
        ? '—'
        : _formatUnitCost(cost.movingAvgCost);
    final ledgerText = MoneyFormatter.formatMinor(cost.ledgerValueVnd);
    final methodLabel = cost.method == CostMethod.periodic
        ? 'Phương pháp: Bình quân cuối kỳ'
        : 'Phương pháp: Bình quân liên hoàn';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Giá vốn',
            style: TextStyle(
              fontSize: 13,
              height: 20 / 13,
              color: Color(0xFF4A535E),
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          VKeyValueRow(
            label: 'Giá vốn chính thức',
            value: officialText,
            mono: !cost.provisional && cost.officialUnitCost != null,
          ),
          VKeyValueRow(
            label: 'Bình quân liên hoàn',
            value: movingText,
            mono: cost.movingAvgCost != null,
          ),
          VKeyValueRow(
            label: 'Giá trị tồn (sổ)',
            value: ledgerText,
            mono: true,
          ),
          const SizedBox(height: VSpacing.space2),
          Container(
            padding: const EdgeInsets.only(top: VSpacing.space3),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.borderDefault)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  methodLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    color: Color(0xFF4A535E),
                  ),
                ),
                if (cost.provisional) ...[
                  const SizedBox(height: VSpacing.space1),
                  const Text(
                    'Xuất kho đang dùng giá tạm (bình quân liên hoàn).',
                    style: TextStyle(
                      fontSize: 13,
                      height: 20 / 13,
                      color: Color(0xFF4A535E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

