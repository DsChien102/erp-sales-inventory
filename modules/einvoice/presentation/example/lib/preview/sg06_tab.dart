import 'package:flutter/material.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

import 'preview_helpers.dart';
import 'preview_section.dart';

class EInvoiceSg06Tab extends StatelessWidget {
  const EInvoiceSg06Tab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SG06-O01 — Tài liệu hóa đơn / Idle',
        description: 'InvoiceDocumentsActionSheet · idle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InvoiceDocumentsActionSheet(
              state: InvoiceDocumentsSheetState.idle,
              onSelectPdf: previewNoop,
              onSelectXml: previewNoop,
            ),
            Builder(
              builder: (ctx) => PreviewActionButton(
                label: 'Open documents sheet',
                onPressed: () => showInvoiceDocumentsActionSheet(ctx),
              ),
            ),
          ],
        ),
      ),
      const PreviewSection(
        title: 'SG06-O02 — Đang chuẩn bị bản PDF',
        description: 'InvoiceDocumentsActionSheet · loadingPdf',
        child: InvoiceDocumentsActionSheet(
          state: InvoiceDocumentsSheetState.loadingPdf,
          onSelectPdf: previewNoop,
          onSelectXml: previewNoop,
        ),
      ),
      const PreviewSection(
        title: 'SG06-O03 — Đang chuẩn bị tệp XML',
        description: 'InvoiceDocumentsActionSheet · loadingXml',
        child: InvoiceDocumentsActionSheet(
          state: InvoiceDocumentsSheetState.loadingXml,
          onSelectPdf: previewNoop,
          onSelectXml: previewNoop,
        ),
      ),
    ]);
  }
}
