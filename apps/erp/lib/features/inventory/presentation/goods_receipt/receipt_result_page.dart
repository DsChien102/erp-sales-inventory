import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/k4_result_page.dart';

class ReceiptResultPage extends StatelessWidget {
  const ReceiptResultPage({
    super.key,
    required this.result,
    required this.onViewReceipt,
    required this.onViewStock,
    required this.onNewReceipt,
    this.onBack,
  });

  final RecordReceiptResult result;
  final ValueChanged<String> onViewReceipt;
  final VoidCallback onViewStock;
  final VoidCallback onNewReceipt;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final facts = <VKeyValueRow>[
      VKeyValueRow(
        label: 'Số phiếu',
        value: result.receiptNo,
        mono: true,
      ),
      VKeyValueRow(
        label: 'Nhà cung cấp',
        value: result.supplierName,
      ),
      if (result.supplierDocNo != null && result.supplierDocNo!.isNotEmpty)
        VKeyValueRow(
          label: 'Số chứng từ',
          value: result.supplierDocNo!,
        ),
      VKeyValueRow(
        label: 'Người nhận',
        value: result.createdByName,
      ),
      VKeyValueRow(
        label: 'Ngày nhập',
        value: result.businessDate,
      ),
      VKeyValueRow(
        label: 'Số dòng hàng',
        value: '${result.lineCount} dòng (${result.lotCount} lô)',
      ),
      VKeyValueRow(
        label: 'Tổng giá gốc',
        value: '${MoneyFormatter.formatMinorPlain(result.landedTotalVnd)} đ',
        emphasized: true,
      ),
      if (result.reachedPrograms.isNotEmpty) ...[
        for (final prog in result.reachedPrograms)
          VKeyValueRow(
            label: 'Chương trình đạt mốc',
            value: prog.name,
            emphasized: true,
          ),
      ],
      for (final sc in result.stockChanges)
        VKeyValueRow(
          label: sc.productName,
          value: '${_formatNum(sc.before)} → ${_formatNum(sc.after)} ${sc.baseUom}',
          mono: true,
        ),
    ];

    return K4ResultPage(
      screenTitle: 'Kết quả nhận hàng',
      onBack: onBack ??
          () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              onViewReceipt(result.receiptId);
            }
          },
      kind: K4Kind.success,
      title: 'Ghi nhận hàng thành công',
      description: 'Phiếu nhận đã được lưu vào hệ thống và tăng tồn kho.',
      facts: facts,
      extra: Column(
        children: [
          VButton(
            label: 'Xem phiếu ${result.receiptNo}',
            variant: VButtonVariant.link,
            onPressed: () => onViewReceipt(result.receiptId),
          ),
        ],
      ),
      next: [
        InventoryFooterAction(
          label: 'Xem tồn kho',
          onPressed: onViewStock,
        ),
        InventoryFooterAction(
          label: 'Nhận tiếp',
          primary: true,
          onPressed: onNewReceipt,
        ),
      ],
    );
  }

  static String _formatNum(num n) {
    if (n % 1 == 0) return n.toInt().toString();
    return n.toString();
  }
}
