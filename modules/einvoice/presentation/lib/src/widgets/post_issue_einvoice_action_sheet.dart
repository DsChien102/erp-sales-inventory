import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import '../support/einvoice_status_interaction.dart';
import '../support/order_einvoice_copy.dart';
import 'einvoice_action_item.dart';

/// Actions returned by [showPostIssueEInvoiceActionSheet].
enum PostIssueAction { viewOfficial, documents, send }

/// State passed to [PostIssueEInvoiceActionSheet].
class PostIssueSheetState {
  const PostIssueSheetState({
    this.deliveryStatus = DeliveryDisplayState.notSent,
    this.isOfficialViewLoading = false,
    this.isDeliveryPending = false,
  });

  final DeliveryDisplayState deliveryStatus;
  final bool isOfficialViewLoading;
  final bool isDeliveryPending;

  static const idle = PostIssueSheetState();
  static const officialViewLoading = PostIssueSheetState(
    isOfficialViewLoading: true,
  );
}

/// Shows the post-issue E-Invoice action sheet.
///
/// [onViewOfficial] keeps this sheet open and starts official-view loading.
/// Documents and send still pop with [PostIssueAction].
Future<PostIssueAction?> showPostIssueEInvoiceActionSheet(
  BuildContext context, {
  PostIssueSheetState state = const PostIssueSheetState(),
  Stream<PostIssueSheetState>? states,
  VoidCallback? onViewOfficial,
}) {
  return showVBottomSheet<PostIssueAction>(
    context: context,
    child: StreamBuilder<PostIssueSheetState>(
      initialData: state,
      stream: states,
      builder: (context, snapshot) => PostIssueEInvoiceActionSheet(
        state: snapshot.data ?? state,
        onViewOfficial: onViewOfficial,
      ),
    ),
  );
}

/// Post-issue E-Invoice action sheet.
///
/// Implements SG02-O05 (delivery variants A/B/C/D) and SG02-O06 (loading).
class PostIssueEInvoiceActionSheet extends StatelessWidget {
  const PostIssueEInvoiceActionSheet({
    super.key,
    this.state = const PostIssueSheetState(),
    this.onViewOfficial,
  });

  final PostIssueSheetState state;
  final VoidCallback? onViewOfficial;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    void select(PostIssueAction action) {
      Navigator.of(context).pop(action);
    }

    final isActionsEnabled = !state.isOfficialViewLoading;
    final isSendInteractive =
        isActionsEnabled &&
        !state.isDeliveryPending &&
        EInvoiceStatusInteraction.allowsTapForDelivery(state.deliveryStatus);

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
              EInvoiceActionItem(
                key: const Key('action_view_official'),
                icon: VIcons.visibility,
                title: OrderEInvoiceCopy.viewOfficialTitle,
                supportingText: OrderEInvoiceCopy.viewOfficialSupporting,
                enabled: true,
                loading: state.isOfficialViewLoading,
                onTap: state.isOfficialViewLoading ? null : onViewOfficial,
              ),
              EInvoiceActionItem(
                key: const Key('action_documents'),
                icon: VIcons.fileCheck,
                title: OrderEInvoiceCopy.documentsTitle,
                supportingText: OrderEInvoiceCopy.documentsSupporting,
                enabled: isActionsEnabled,
                onTap: isActionsEnabled ? () => select(PostIssueAction.documents) : null,
              ),
              EInvoiceActionItem(
                key: const Key('action_send'),
                icon: VIcons.send,
                title: OrderEInvoiceCopy.sendTitle,
                supportingText: OrderEInvoiceCopy.sendSupporting,
                badge: _deliveryBadge,
                enabled: isSendInteractive,
                onTap: isSendInteractive ? () => select(PostIssueAction.send) : null,
              ),
              const VGap.lg(),
            ],
          ),
        ),
      ),
    );
  }

  VBadge get _deliveryBadge {
    return switch (state.deliveryStatus) {
      DeliveryDisplayState.notSent => const VBadge(
        label: OrderEInvoiceCopy.deliveryNotSent,
        tone: VComponentTone.neutral,
      ),
      DeliveryDisplayState.sending => const VBadge(
        label: OrderEInvoiceCopy.deliverySending,
        tone: VComponentTone.primary,
      ),
      DeliveryDisplayState.sent => const VBadge(
        label: OrderEInvoiceCopy.deliverySent,
        tone: VComponentTone.success,
      ),
      DeliveryDisplayState.failed => const VBadge(
        label: OrderEInvoiceCopy.deliverySendFailed,
        tone: VComponentTone.danger,
      ),
      DeliveryDisplayState.unknown => const VBadge(
        label: OrderEInvoiceCopy.deliveryUnknown,
        tone: VComponentTone.warning,
      ),
    };
  }
}
