import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';

import 'package:erp/features/sales/logic/sales_order_detail_cubit.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_issue.dart';
import '../pages/sales_receipt_preview_page.dart';
import '../widgets/sales_result_receipt_sheet.dart';
import 'sales_pdf_runner.dart';
import 'sales_receipt_pdf_generator.dart';
import 'sales_transaction_result_mapper.dart';

/// «Đơn gốc» tab helpers: as-sold receipt computed on read (no activity).
abstract final class SalesOrderDetailOriginalReceiptActions {
  static Future<void> open({
    required BuildContext context,
    required SalesOrderDetailCubit cubit,
    required SalesResultReceiptAction action,
    required String Function(SalesTransactionResultIssue? issue) issueMessage,
  }) async {
    try {
      final document = await cubit.viewOriginalReceipt();
      if (!context.mounted) return;
      switch (action) {
        case SalesResultReceiptAction.view:
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SalesReceiptPreviewPage(
                document: document,
                onPrint: (doc) => printDocument(context, doc),
                onShare: (doc) => shareDocument(context, doc),
              ),
            ),
          );
        case SalesResultReceiptAction.print:
          await printDocument(context, document);
        case SalesResultReceiptAction.share:
          await shareDocument(context, document);
      }
    } catch (error) {
      if (!context.mounted) return;
      VToast.show(
        context,
        title: 'Thao tác phiếu thất bại',
        message: issueMessage(SalesTransactionResultMapper.issueFor(error)),
        type: VToastType.danger,
      );
    }
  }

  static Future<void> printDocument(
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

  static Future<void> shareDocument(
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
