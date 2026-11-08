import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/order_einvoice_post_issue_copy.dart';
import 'einvoice_action_item.dart';

/// Document action selected from [InvoiceDocumentsActionSheet].
enum InvoiceDocumentsAction { pdf, xml }

/// Presentation state for SG-06 document sheet variants.
enum InvoiceDocumentsSheetState {
  idle,
  loadingPdf,
  loadingXml,
}

/// Async handler for PDF/XML actions; `true` means native handoff completed.
typedef InvoiceDocumentActionHandler = Future<bool> Function();

/// Shows the SG-06 invoice documents action sheet.
///
/// Opening the sheet alone does not start a document request.
/// [onSelectPdf] / [onSelectXml] keep this sheet open until handoff succeeds
/// (`true`) or the caller returns `false` (sheet stays open).
Future<InvoiceDocumentsAction?> showInvoiceDocumentsActionSheet(
  BuildContext context, {
  InvoiceDocumentsSheetState state = InvoiceDocumentsSheetState.idle,
  Stream<InvoiceDocumentsSheetState>? states,
  InvoiceDocumentActionHandler? onSelectPdf,
  InvoiceDocumentActionHandler? onSelectXml,
}) {
  return showVBottomSheet<InvoiceDocumentsAction>(
    context: context,
    child: StreamBuilder<InvoiceDocumentsSheetState>(
      initialData: state,
      stream: states,
      builder: (context, snapshot) => InvoiceDocumentsActionSheet(
        state: snapshot.data ?? state,
        onSelectPdf: onSelectPdf,
        onSelectXml: onSelectXml,
      ),
    ),
  );
}

/// Action sheet to choose PDF or XML document retrieval (SG06-O01/O02/O03).
///
/// Loading is action-specific: the selected row shows a spinner; the sibling
/// is disabled until the request finishes. Copy stays stable on both rows.
class InvoiceDocumentsActionSheet extends StatelessWidget {
  const InvoiceDocumentsActionSheet({
    super.key,
    this.state = InvoiceDocumentsSheetState.idle,
    this.onSelectPdf,
    this.onSelectXml,
  });

  final InvoiceDocumentsSheetState state;

  /// When null, pops the host route with [InvoiceDocumentsAction.pdf].
  final InvoiceDocumentActionHandler? onSelectPdf;

  /// When null, pops the host route with [InvoiceDocumentsAction.xml].
  final InvoiceDocumentActionHandler? onSelectXml;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final isPdfLoading = state == InvoiceDocumentsSheetState.loadingPdf;
    final isXmlLoading = state == InvoiceDocumentsSheetState.loadingXml;
    final isBusy = isPdfLoading || isXmlLoading;

    Future<void> selectPdf() async {
      final handler = onSelectPdf;
      if (handler == null) {
        Navigator.of(context).pop(InvoiceDocumentsAction.pdf);
        return;
      }

      final handedOff = await handler();
      if (handedOff && context.mounted) {
        Navigator.of(context).pop(InvoiceDocumentsAction.pdf);
      }
    }

    Future<void> selectXml() async {
      final handler = onSelectXml;
      if (handler == null) {
        Navigator.of(context).pop(InvoiceDocumentsAction.xml);
        return;
      }

      final handedOff = await handler();
      if (handedOff && context.mounted) {
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
                  OrderEInvoicePostIssueCopy.documentsSheetTitle,
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              EInvoiceActionItem(
                key: const Key('action_save_pdf'),
                icon: VIcons.file,
                title: OrderEInvoicePostIssueCopy.savePdfTitle,
                supportingText: OrderEInvoicePostIssueCopy.savePdfSupporting,
                loading: isPdfLoading,
                enabled: !isXmlLoading,
                onTap: isBusy ? null : () => unawaited(selectPdf()),
              ),
              EInvoiceActionItem(
                key: const Key('action_save_xml'),
                icon: VIcons.fileText,
                title: OrderEInvoicePostIssueCopy.saveXmlTitle,
                supportingText: OrderEInvoicePostIssueCopy.saveXmlSupporting,
                loading: isXmlLoading,
                enabled: !isPdfLoading,
                onTap: isBusy ? null : () => unawaited(selectXml()),
              ),
              const VGap.lg(),
            ],
          ),
        ),
      ),
    );
  }
}
