import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Dải 4 số: Đầu kỳ · Nhập · Xuất · Cuối kỳ (`.bj15-strip`).
class StockCardStrip extends StatelessWidget {
  const StockCardStrip({super.key, required this.summary});

  final StockCardSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    Widget item(String label, num value) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
                fontSize: 12,
                height: 16 / 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatQuantity(value.toDouble()),
              style: VTypography.monoNumeric.copyWith(
                color: colors.textPrimary,
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          item('Đầu kỳ', summary.openingQty),
          const SizedBox(width: VSpacing.space2),
          item('Nhập', summary.inQty),
          const SizedBox(width: VSpacing.space2),
          item('Xuất', summary.outQty),
          const SizedBox(width: VSpacing.space2),
          item('Cuối kỳ', summary.closingQty),
        ],
      ),
    );
  }
}
