import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/order_einvoice_copy.dart';
import 'einvoice_action_item.dart';

/// Actions returned by [showPreIssueEInvoiceActionSheet].
enum PreIssueAction { issue, preview, correctBuyer }

/// State passed to [PreIssueEInvoiceActionSheet] to determine action
/// availability and loading indicators.
class PreIssueSheetState {
  const PreIssueSheetState({
    this.isPreviewLoading = false,
    this.isBuyerNotReady = false,
    this.isPreviewEnabled = true,
  });

  final bool isPreviewLoading;
  final bool isBuyerNotReady;
  final bool isPreviewEnabled;

  static const idle = PreIssueSheetState();
  static const previewLoading = PreIssueSheetState(isPreviewLoading: true);
  static const buyerNotReady = PreIssueSheetState(
    isBuyerNotReady: true,
    isPreviewEnabled: true,
  );
}

/// Shows the pre-issue E-Invoice action sheet.
Future<PreIssueAction?> showPreIssueEInvoiceActionSheet(
  BuildContext context, {
  PreIssueSheetState state = const PreIssueSheetState(),
}) {
  return showVBottomSheet<PreIssueAction>(
    context: context,
    child: PreIssueEInvoiceActionSheet(state: state),
  );
}

/// Pre-issue E-Invoice action sheet.
///
/// Implements SG02-O01/O02/O03/O04 and buyerNotReady (design O07).
class PreIssueEInvoiceActionSheet extends StatelessWidget {
  const PreIssueEInvoiceActionSheet({
    super.key,
    this.state = const PreIssueSheetState(),
  });

  final PreIssueSheetState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    void select(PreIssueAction action) {
      Navigator.of(context).pop(action);
    }

    final isIssueEnabled =
        !state.isBuyerNotReady && !state.isPreviewLoading;
    final isPreviewEnabled =
        state.isPreviewEnabled && !state.isPreviewLoading;
    final isSendEnabled = false; // always disabled pre-issue

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
                  OrderEInvoiceCopy.sheetTitle,
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (state.isBuyerNotReady) ...[
                _BuyerNotReadyWarning(
                  onCorrect: () => select(PreIssueAction.correctBuyer),
                ),
              ],
              EInvoiceActionItem(
                key: const Key('action_issue'),
                icon: VIcons.receipt,
                title: OrderEInvoiceCopy.issueTitle,
                supportingText: state.isBuyerNotReady
                    ? OrderEInvoiceCopy.issueDisabledSupporting
                    : OrderEInvoiceCopy.issueSupporting,
                enabled: isIssueEnabled,
                onTap: () => select(PreIssueAction.issue),
              ),
              EInvoiceActionItem(
                key: const Key('action_preview'),
                icon: VIcons.visibility,
                title: OrderEInvoiceCopy.previewTitle,
                supportingText: OrderEInvoiceCopy.previewSupporting,
                enabled: isPreviewEnabled,
                loading: state.isPreviewLoading,
                onTap: () => select(PreIssueAction.preview),
              ),
              EInvoiceActionItem(
                key: const Key('action_send'),
                icon: VIcons.send,
                title: OrderEInvoiceCopy.sendTitle,
                supportingText: OrderEInvoiceCopy.sendSupporting,
                badge: const VBadge(
                  label: OrderEInvoiceCopy.deliveryNotSent,
                  status: VBadgeStatus.draft,
                  isSmall: true,
                ),
                enabled: isSendEnabled,
              ),
              const VGap.lg(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyerNotReadyWarning extends StatelessWidget {
  const _BuyerNotReadyWarning({required this.onCorrect});

  final VoidCallback onCorrect;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VBanner(
            status: VBannerStatus.warning,
            title: OrderEInvoiceCopy.buyerWarningTitle,
            description: OrderEInvoiceCopy.buyerWarningDescription,
          ),
          const VGap.sm(),
          Align(
            alignment: Alignment.centerLeft,
            child: VButton(
              label: OrderEInvoiceCopy.buyerCorrectionAction,
              variant: VButtonVariant.link,
              foregroundColor: colors.textBrand,
              onPressed: onCorrect,
            ),
          ),
        ],
      ),
    );
  }
}
