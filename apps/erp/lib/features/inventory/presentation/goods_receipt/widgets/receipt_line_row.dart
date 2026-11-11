import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_line_rules.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';

class ReceiptLineRow extends StatelessWidget {
  const ReceiptLineRow({
    super.key,
    required this.line,
    required this.knownLots,
    required this.isSelected,
    required this.onTap,
  });

  final ReceiptLineDraft line;
  final List<KnownLot> knownLots;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final subline = offerSummary(line);
    final reason = lineInvalidReason(line, knownLots: knownLots);
    final isDone = reason == null;

    // Tính thành tiền a_i = gross - tierDiscount
    final gross = (line.paidQuantity * line.unitPriceVnd).round();
    final tier = line.tierPercent != null
        ? (gross * line.tierPercent! / 100.0).round()
        : 0;
    final purchase = gross - tier;

    final qtyStr = '${formatQuantity(line.totalQuantity.toDouble())} ${line.unit.name}';
    final amountStr = MoneyFormatter.formatMinor(purchase);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.r12),
      child: Container(
        padding: const EdgeInsets.all(VSpacing.space3),
        decoration: BoxDecoration(
          color: isSelected ? colors.surfaceBrand : colors.surface,
          borderRadius: BorderRadius.circular(VRadius.r12),
          border: Border.all(
            color: isSelected
                ? colors.borderBrand
                : (isDone ? colors.borderDefault : colors.borderStrong),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.product.name,
                        style: VTypography.bodyDefault.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${line.product.code} · ${line.unit.name}',
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      qtyStr,
                      style: VTypography.bodyDefault.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amountStr,
                      style: VTypography.monoNumeric.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (subline != null) ...[
              const SizedBox(height: VSpacing.space1),
              Text(
                subline,
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (!isDone) ...[
              const SizedBox(height: VSpacing.space1),
              Text(
                reason,
                style: VTypography.bodySmall.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
