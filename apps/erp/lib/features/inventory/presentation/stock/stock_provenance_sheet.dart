import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

String formatStockAsOfDot(DateTime asOf) {
  final hh = asOf.hour.toString().padLeft(2, '0');
  final mm = asOf.minute.toString().padLeft(2, '0');
  final dd = asOf.day.toString().padLeft(2, '0');
  final mo = asOf.month.toString().padLeft(2, '0');
  final yyyy = asOf.year.toString();
  return '$hh:$mm · $dd/$mo/$yyyy';
}

String _formatDateDdMmYyyy(DateTime date) {
  final dd = date.day.toString().padLeft(2, '0');
  final mo = date.month.toString().padLeft(2, '0');
  final yyyy = date.year.toString();
  return '$dd/$mo/$yyyy';
}

class StockProvenanceSheet extends StatelessWidget {
  final StockDetail detail;
  final VoidCallback? onOpenReceipt;
  final VoidCallback? onOpenStockCard;

  const StockProvenanceSheet({
    super.key,
    required this.detail,
    this.onOpenReceipt,
    this.onOpenStockCard,
  });

  static Future<void> show({
    required BuildContext context,
    required StockDetail detail,
    VoidCallback? onOpenReceipt,
    VoidCallback? onOpenStockCard,
  }) {
    return showVAdaptiveSheet<void>(
      context: context,
      title: 'Nguồn và thời điểm cập nhật',
      child: StockProvenanceSheet(
        detail: detail,
        onOpenReceipt: onOpenReceipt,
        onOpenStockCard: onOpenStockCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mv = detail.latestMovement;
    final String mvLabel;
    final String mvValue;
    if (mv != null) {
      mvLabel = '${mv.label} gần nhất';
      final sign = mv.delta > 0 ? '+' : '';
      mvValue =
          '${_formatDateDdMmYyyy(mv.businessDate)} · $sign${formatStockQuantity(mv.delta, detail.uom)}';
    } else {
      mvLabel = 'Biến động gần nhất';
      mvValue = 'Chưa có biến động';
    }

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${detail.name} · ${detail.warehouseName}',
            style: TextStyle(
              fontSize: 13,
              height: 20 / 13,
              color: context.vColors.textSecondary,
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          VKeyValueGroup(
            rows: [
              VKeyValueRow(
                label: 'Dữ liệu đến',
                value: formatStockAsOfDot(detail.asOf),
                mono: true,
              ),
              VKeyValueRow(
                label: mvLabel,
                value: mvValue,
                mono: mv != null,
              ),
            ],
          ),
          if (onOpenReceipt != null && mv != null && mv.kind == 'RECEIPT') ...[
            const SizedBox(height: VSpacing.space2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onOpenReceipt,
                child: const Text('Mở phiếu nhận'),
              ),
            ),
          ],
          if (onOpenStockCard != null) ...[
            const SizedBox(height: VSpacing.space3),
            VButton(
              label: 'Xem thẻ kho và lịch sử',
              variant: VButtonVariant.secondary,
              leading: VIcons.history,
              onPressed: onOpenStockCard,
            ),
          ],
        ],
      ),
    );
  }
}
