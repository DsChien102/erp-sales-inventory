import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

import '../models/sales_order/sales_order_detail_vm.dart';
import '../models/sales_receipt/sales_receipt_device_action.dart';
import '../support/sales_pdf_runner.dart';
import '../support/sales_receipt_pdf_generator.dart';
import 'sales_receipt_preview_page.dart';

/// Backward-compatible route entry for sales slip preview, now receipt-based.
class SalesOrderSlipPreviewPage extends StatelessWidget {
  const SalesOrderSlipPreviewPage({
    super.key,
    required this.orderId,
    this.orderNumber,
    this.orderVm,
    this.receipt,
    this.onPrint,
    this.onShare,
  });

  final String orderId;
  final String? orderNumber;
  final SalesOrderDetailVm? orderVm;
  final SalesReceiptDto? receipt;
  final SalesReceiptDeviceAction? onPrint;
  final SalesReceiptDeviceAction? onShare;

  @override
  Widget build(BuildContext context) {
    final resolvedReceipt = receipt;
    if (resolvedReceipt == null) {
      return VPageScaffold(
        key: const Key('wgt_sales_order_slip_invalid_entry'),
        title: 'Phiếu bán hàng',
        showBackButton: true,
        body: const Center(
          child: VText(
            'Thiếu dữ liệu phiếu bán hàng hợp lệ để xem trước.',
            variant: VTextVariant.bodyDefault,
          ),
        ),
      );
    }

    return SalesReceiptPreviewPage(
      key: const Key('wgt_sales_order_slip_preview_page'),
      receipt: resolvedReceipt,
      onPrint: onPrint ?? (document) => _print(context, document),
      onShare: onShare ?? (document) => _share(context, document),
    );
  }

  Future<void> _print(
    BuildContext context,
    SalesReceiptDocumentDto document,
  ) async {
    final bytes = await SalesReceiptPdfGenerator.generate(document);
    if (!context.mounted) return;
    await SalesPdfRunner.print(
      context: context,
      bytes: bytes,
      name: SalesReceiptPdfGenerator.sanitizeFileName(document.receiptNumber),
    );
  }

  Future<void> _share(
    BuildContext context,
    SalesReceiptDocumentDto document,
  ) async {
    final bytes = await SalesReceiptPdfGenerator.generate(document);
    if (!context.mounted) return;
    await SalesPdfRunner.share(
      context: context,
      bytes: bytes,
      filename: SalesReceiptPdfGenerator.sanitizeFileName(document.receiptNumber),
    );
  }
}
