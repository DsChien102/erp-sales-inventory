import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';

class ReceiptRecordCard extends StatelessWidget {
  const ReceiptRecordCard({
    super.key,
    required this.row,
    this.onTap,
  });

  final ReceiptListRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hàng 1: receipt_no · supplier_name
          Text(
            '${row.receiptNo} · ${row.supplierName}',
            style: VTypography.labelDefault,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: VSpacing.space1),
          // Hàng 2: line_count dòng (lot_count lô)
          Text(
            '${row.lineCount} dòng (${row.lotCount} lô)',
            style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: VSpacing.space1),
          // Hàng 3: landed_total_vnd
          Text(
            '${MoneyFormatter.formatMinorPlain(row.landedTotalVnd)} đ',
            style: VTypography.labelDefault.copyWith(color: colors.primary),
          ),
          const SizedBox(height: VSpacing.space1),
          // Hàng 4: business_date · created_by_name
          Text(
            '${row.businessDate} · ${row.createdByName}',
            style: VTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

