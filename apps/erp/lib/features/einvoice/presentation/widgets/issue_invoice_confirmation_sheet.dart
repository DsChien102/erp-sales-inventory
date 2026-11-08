import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/order_einvoice_copy.dart';

/// Summary fields shown on the issue confirmation sheet (preview/DTO-shaped).
class IssueInvoiceConfirmationSummary {
  const IssueInvoiceConfirmationSummary({
    required this.orderReference,
    required this.orderTotal,
    required this.templateNumber,
    required this.templateSymbol,
    required this.authorityMode,
  });

  final String orderReference;
  final String orderTotal;
  final String templateNumber;
  final String templateSymbol;
  final String authorityMode;

  /// Preview fixture from approved design (not a business constant).
  static const previewFixture = IssueInvoiceConfirmationSummary(
    orderReference: '#DH-000129',
    orderTotal: '4.445.238đ',
    templateNumber: '1/001',
    templateSymbol: 'C26TAA',
    authorityMode: 'Có mã CQT',
  );
}

/// Shows the SG-03 issue confirmation sheet.
///
/// Returns `true` when the user confirms, `false` when cancelled/dismissed.
Future<bool> showIssueInvoiceConfirmationSheet(
  BuildContext context, {
  required IssueInvoiceConfirmationSummary summary,
}) async {
  final result = await showVAdaptiveSheet<bool>(
    context: context,
    title: OrderEInvoiceCopy.issueConfirmationTitle,
    semanticLabel: OrderEInvoiceCopy.issueConfirmationTitle,
    child: IssueInvoiceConfirmationSheet(summary: summary),
  );
  return result ?? false;
}

/// Confirmation sheet before submitting a manual E-Invoice issue command.
///
/// Implements SG03-O01-A / SG03-O02. SG03-O01-B remains unresolved (GAP-01).
class IssueInvoiceConfirmationSheet extends StatelessWidget {
  const IssueInvoiceConfirmationSheet({
    super.key,
    required this.summary,
    this.onConfirm,
    this.onCancel,
  });

  final IssueInvoiceConfirmationSummary summary;

  /// When null, pops the host route with `true` (sheet presentation).
  final VoidCallback? onConfirm;

  /// When null, pops the host route with `false` (sheet presentation).
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    void confirm() {
      if (onConfirm != null) {
        onConfirm!();
      } else {
        Navigator.of(context).pop(true);
      }
    }

    void cancel() {
      if (onCancel != null) {
        onCancel!();
      } else {
        Navigator.of(context).pop(false);
      }
    }

    final line1 = OrderEInvoiceCopy.issueConfirmationSummaryLine1(
      orderReference: summary.orderReference,
      orderTotal: summary.orderTotal,
    );
    final line2 = OrderEInvoiceCopy.issueConfirmationSummaryLine2(
      templateNumber: summary.templateNumber,
      templateSymbol: summary.templateSymbol,
      authorityMode: summary.authorityMode,
    );

    return Material(
      color: colors.surface.withValues(alpha: 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space3,
          VSpacing.space4,
          VSpacing.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            VText(
              line1,
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.xs(),
            VText(
              line2,
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.lg(),
            VButton(
              key: const Key('action_confirm_issue'),
              label: OrderEInvoiceCopy.issueConfirmationConfirm,
              variant: VButtonVariant.primary,
              fullWidth: true,
              onPressed: confirm,
            ),
            const VGap.sm(),
            VButton(
              key: const Key('action_cancel_issue'),
              label: OrderEInvoiceCopy.issueConfirmationCancel,
              variant: VButtonVariant.secondary,
              fullWidth: true,
              onPressed: cancel,
            ),
          ],
        ),
      ),
    );
  }
}
