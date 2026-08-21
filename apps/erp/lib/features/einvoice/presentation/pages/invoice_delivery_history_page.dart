import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

/// Thin ERP host for SG07-D01 delivery history.
///
/// Composes [InvoiceDeliveryHistoryView]; no live RPC in this slice.
class InvoiceDeliveryHistoryPage extends StatelessWidget {
  const InvoiceDeliveryHistoryPage({
    super.key,
    required this.summary,
    required this.rows,
    this.onBack,
  });

  final InvoiceDeliveryHistorySummary summary;
  final List<InvoiceDeliveryHistoryRowData> rows;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      title: SendInvoiceCopy.historyPageTitle,
      showBackButton: true,
      leading: onBack == null
          ? null
          : IconButton(
              icon: VIcon(
                icon: VIcons.chevronLeft,
                color: context.vColors.textPrimary,
              ),
              onPressed: onBack,
            ),
      body: InvoiceDeliveryHistoryView(
        summary: summary,
        rows: rows,
      ),
    );
  }
}
