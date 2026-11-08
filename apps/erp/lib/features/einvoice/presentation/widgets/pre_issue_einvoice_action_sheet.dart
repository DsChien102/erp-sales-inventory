import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/order_einvoice_copy.dart';
import 'einvoice_action_item.dart';
import 'issuance_failure_banner.dart';

/// Actions returned by [showPreIssueEInvoiceActionSheet].
enum PreIssueAction { issue, preview, correctBuyer }

/// State passed to [PreIssueEInvoiceActionSheet] to determine action
/// availability and loading indicators.
class PreIssueSheetState {
  const PreIssueSheetState({
    this.isPreviewLoading = false,
    this.isBuyerNotReady = false,
    this.showBuyerCorrection = true,
    this.isPreviewEnabled = true,
    this.isProviderConnected = true,
    this.isFailed = false,
    this.failureCode,
    this.lastFailureMessage,
  });

  final bool isPreviewLoading;
  final bool isBuyerNotReady;

  /// False when the order has no partner to open on the edit screen.
  final bool showBuyerCorrection;
  final bool isPreviewEnabled;

  /// False when issuance readiness reports `PROVIDER_NOT_CONNECTED`.
  final bool isProviderConnected;
  final bool isFailed;
  final String? failureCode;
  final String? lastFailureMessage;

  static const idle = PreIssueSheetState();
  static const previewLoading = PreIssueSheetState(isPreviewLoading: true);
  static const buyerNotReady = PreIssueSheetState(
    isBuyerNotReady: true,
    isPreviewEnabled: true,
  );
}

/// Shows the pre-issue E-Invoice action sheet.
///
/// [onPreview] keeps this sheet open and starts preview loading.
/// Issue and buyer-correction still pop with [PreIssueAction].
Future<PreIssueAction?> showPreIssueEInvoiceActionSheet(
  BuildContext context, {
  PreIssueSheetState state = const PreIssueSheetState(),
  Stream<PreIssueSheetState>? states,
  VoidCallback? onPreview,
}) {
  return showVAdaptiveSheet<PreIssueAction>(
    context: context,
    title: OrderEInvoiceCopy.sheetTitle,
    semanticLabel: OrderEInvoiceCopy.sheetTitle,
    child: StreamBuilder<PreIssueSheetState>(
      initialData: state,
      stream: states,
      builder: (context, snapshot) => PreIssueEInvoiceActionSheet(
        state: snapshot.data ?? state,
        onPreview: onPreview,
      ),
    ),
  );
}

/// Pre-issue E-Invoice action sheet.
///
/// Implements SG02-O01/O02/O03/O04 and buyerNotReady (design O07).
class PreIssueEInvoiceActionSheet extends StatelessWidget {
  const PreIssueEInvoiceActionSheet({
    super.key,
    this.state = const PreIssueSheetState(),
    this.onPreview,
  });

  final PreIssueSheetState state;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    void select(PreIssueAction action) {
      Navigator.of(context).pop(action);
    }

    final isIssueEnabled =
        state.isProviderConnected && !state.isBuyerNotReady && !state.isPreviewLoading;
    final isPreviewEnabled = state.isPreviewEnabled && !state.isPreviewLoading;
    final isSendEnabled = false; // always disabled pre-issue

    return Material(
      color: colors.surface.withValues(alpha: 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.isFailed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.space4,
                  vertical: VSpacing.space2,
                ),
                child: IssuanceFailureBanner(
                  failureCode: state.failureCode,
                  lastFailureMessage: state.lastFailureMessage,
                ),
              ),
            ],
            if (state.isBuyerNotReady) ...[
              _BuyerNotReadyWarning(
                showCorrection: state.showBuyerCorrection,
                onCorrect: state.isPreviewLoading
                    ? null
                    : () => select(PreIssueAction.correctBuyer),
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
              onTap: isIssueEnabled ? () => select(PreIssueAction.issue) : null,
            ),
            EInvoiceActionItem(
              key: const Key('action_preview'),
              icon: VIcons.visibility,
              title: OrderEInvoiceCopy.previewTitle,
              supportingText: OrderEInvoiceCopy.previewSupporting,
              enabled: state.isPreviewEnabled,
              loading: state.isPreviewLoading,
              onTap: isPreviewEnabled
                  ? () {
                      if (onPreview != null) {
                        onPreview!();
                      } else {
                        select(PreIssueAction.preview);
                      }
                    }
                  : null,
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
            const VGap.sm(),
          ],
        ),
      ),
    );
  }
}

class _BuyerNotReadyWarning extends StatelessWidget {
  const _BuyerNotReadyWarning({
    required this.showCorrection,
    this.onCorrect,
  });

  final bool showCorrection;
  final VoidCallback? onCorrect;

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
          if (showCorrection) ...[
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
        ],
      ),
    );
  }
}
