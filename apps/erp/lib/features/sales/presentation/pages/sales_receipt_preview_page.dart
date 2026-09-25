import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

import '../models/sales_receipt/sales_receipt_device_action.dart';
import '../support/sales_receipt_pdf_generator.dart';

class SalesReceiptPreviewPage extends StatelessWidget {
  const SalesReceiptPreviewPage({
    super.key,
    required this.document,
    required this.onPrint,
    required this.onShare,
  });

  final SalesReceiptDocumentDto document;
  final SalesReceiptDeviceAction onPrint;
  final SalesReceiptDeviceAction onShare;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final fileName = SalesReceiptPdfGenerator.sanitizeFileName(
      document.receiptNumber,
    );

    return VPageScaffold(
      key: const Key('wgt_sales_receipt_preview_page'),
      title: 'Phiếu bán hàng',
      showBackButton: true,
      actions: [
        IconButton(
          key: const Key('btn_sales_receipt_preview_print'),
          icon: VIcon(icon: VIcons.printer, color: colors.textPrimary),
          onPressed: () => onPrint(document),
        ),
        IconButton(
          key: const Key('btn_sales_receipt_preview_share'),
          icon: VIcon(icon: VIcons.share2, color: colors.textPrimary),
          onPressed: () => onShare(document),
        ),
      ],
      body: PdfPreview(
        build: (_) => SalesReceiptPdfGenerator.generate(document),
        pdfFileName: fileName,
        useActions: false,
        scrollViewDecoration: BoxDecoration(color: colors.background),
        canChangeOrientation: false,
        canChangePageFormat: false,
        maxPageWidth: 700,
        loadingWidget: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VLoading(),
              const VGap.sm(),
              VText(
                'Đang tạo bản xem trước PDF...',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
