import 'package:flutter/material.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

import 'preview_helpers.dart';
import 'preview_section.dart';

class EInvoiceSg07Tab extends StatelessWidget {
  const EInvoiceSg07Tab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SG07-O01-A — Gửi hóa đơn / Có email đề xuất',
        description: 'SendInvoiceSheet · suggested',
        child: SendInvoiceSheet(
          invoiceNumber: SendInvoiceSheet.previewInvoiceNumber,
          invoiceSymbol: SendInvoiceSheet.previewInvoiceSymbol,
          initialEmail: SendInvoiceSheet.previewSuggestedEmail,
          state: SendInvoiceSheetState.suggested,
          onSubmit: (_) {},
          onCancel: previewNoop,
        ),
      ),
      PreviewSection(
        title: 'SG07-O01-B — Gửi hóa đơn / Chưa có email',
        description: 'SendInvoiceSheet · empty',
        child: SendInvoiceSheet(
          invoiceNumber: SendInvoiceSheet.previewInvoiceNumber,
          invoiceSymbol: SendInvoiceSheet.previewInvoiceSymbol,
          state: SendInvoiceSheetState.empty,
          onSubmit: (_) {},
          onCancel: previewNoop,
        ),
      ),
      PreviewSection(
        title: 'SG07-O01-C — Gửi hóa đơn / Email không hợp lệ',
        description: 'SendInvoiceSheet · invalid',
        child: SendInvoiceSheet(
          invoiceNumber: SendInvoiceSheet.previewInvoiceNumber,
          invoiceSymbol: SendInvoiceSheet.previewInvoiceSymbol,
          initialEmail: 'not-an-email',
          state: SendInvoiceSheetState.invalid,
          onSubmit: (_) {},
          onCancel: previewNoop,
        ),
      ),
      PreviewSection(
        title: 'SG07-O01-D — Đang gửi hóa đơn',
        description: 'SendInvoiceSheet · loading',
        child: SendInvoiceSheet(
          invoiceNumber: SendInvoiceSheet.previewInvoiceNumber,
          invoiceSymbol: SendInvoiceSheet.previewInvoiceSymbol,
          initialEmail: SendInvoiceSheet.previewSuggestedEmail,
          state: SendInvoiceSheetState.loading,
          onSubmit: (_) {},
          onCancel: previewNoop,
        ),
      ),
      PreviewSection(
        title: 'SG07-O02 — Gửi lại hóa đơn',
        description: 'ResendInvoiceSheet',
        child: ResendInvoiceSheet(
          latestEmail: ResendInvoiceSheet.previewLatestEmail,
          latestDateTime: ResendInvoiceSheet.previewLatestDateTime,
          onSubmit: (_) {},
          onCancel: previewNoop,
          onViewHistory: previewNoop,
        ),
      ),
      const PreviewSection(
        title: 'SG07-D01 — Lịch sử gửi hóa đơn',
        description: 'InvoiceDeliveryHistoryView',
        child: PreviewEmbedFrame(
          height: 520,
          child: InvoiceDeliveryHistoryView(
            summary: InvoiceDeliveryHistorySummary.preview,
            rows: InvoiceDeliveryHistoryView.previewRows,
          ),
        ),
      ),
      PreviewSection(
        title: 'SG07-T01/T02 — Gửi thành công',
        description: 'SendSuccessToast (shared)',
        child: Builder(
          builder: (ctx) => PreviewActionButton(
            label: 'Show send success toast',
            onPressed: () => SendSuccessToast.show(ctx),
          ),
        ),
      ),
      PreviewSection(
        title: 'SG07-T03/T04 — Gửi lỗi',
        description: 'SendFailureToast (shared)',
        child: Builder(
          builder: (ctx) => PreviewActionButton(
            label: 'Show send failure toast',
            onPressed: () => SendFailureToast.show(ctx),
          ),
        ),
      ),
    ]);
  }
}
