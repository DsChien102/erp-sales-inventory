import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/invoice_documents_copy.dart';
import 'einvoice_action_item.dart';

/// Document action selected from [InvoiceDocumentsActionSheet].
enum InvoiceDocumentsAction { pdf, xml }

/// Presentation state for SG-06 document sheet variants.
enum InvoiceDocumentsSheetState {
  idle,
  loadingPdf,
  loadingXml,
}

/// Shows the SG-06 invoice documents action sheet.
///
/// Opening the sheet alone does not start a document request.
Future<InvoiceDocumentsAction?> showInvoiceDocumentsActionSheet(
  BuildContext context, {
  InvoiceDocumentsSheetState state = InvoiceDocumentsSheetState.idle,
}) {
  return showVBottomSheet<InvoiceDocumentsAction>(
    context: context,
    child: InvoiceDocumentsActionSheet(state: state),
  );
}

/// Action sheet to choose PDF or XML document retrieval.
///
/// Implements SG06-O01 (idle), SG06-O02 (loading PDF), SG06-O03 (loading XML).
/// Loading is action-specific: only the selected row is non-interactive and
/// shows a spinner; the sibling keeps normal presentation.
class InvoiceDocumentsActionSheet extends StatelessWidget {
  const InvoiceDocumentsActionSheet({
    super.key,
    this.state = InvoiceDocumentsSheetState.idle,
    this.onSelectPdf,
    this.onSelectXml,
  });

  final InvoiceDocumentsSheetState state;

  /// When null, pops the host route with [InvoiceDocumentsAction.pdf].
  final VoidCallback? onSelectPdf;

  /// When null, pops the host route with [InvoiceDocumentsAction.xml].
  final VoidCallback? onSelectXml;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final isPdfLoading = state == InvoiceDocumentsSheetState.loadingPdf;
    final isXmlLoading = state == InvoiceDocumentsSheetState.loadingXml;

    void selectPdf() {
      if (onSelectPdf != null) {
        onSelectPdf!();
      } else {
        Navigator.of(context).pop(InvoiceDocumentsAction.pdf);
      }
    }

    void selectXml() {
      if (onSelectXml != null) {
        onSelectXml!();
      } else {
        Navigator.of(context).pop(InvoiceDocumentsAction.xml);
      }
    }

    return Material(
      color: colors.surface.withValues(alpha: 0),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.space4,
                  VSpacing.space4,
                  VSpacing.space4,
                  VSpacing.space2,
                ),
                child: VText(
                  InvoiceDocumentsCopy.sheetTitle,
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              EInvoiceActionItem(
                key: const Key('action_save_pdf'),
                icon: VIcons.file,
                title: InvoiceDocumentsCopy.savePdfTitle,
                supportingText: InvoiceDocumentsCopy.savePdfSupporting,
                loading: isPdfLoading,
                enabled: !isPdfLoading,
                onTap: isPdfLoading ? null : selectPdf,
              ),
              EInvoiceActionItem(
                key: const Key('action_save_xml'),
                icon: VIcons.fileText,
                title: InvoiceDocumentsCopy.saveXmlTitle,
                supportingText: InvoiceDocumentsCopy.saveXmlSupporting,
                loading: isXmlLoading,
                enabled: !isXmlLoading,
                onTap: isXmlLoading ? null : selectXml,
              ),
              const VGap.lg(),
            ],
          ),
        ),
      ),
    );
  }
}
