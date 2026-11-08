import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../data/models.dart';

import '../support/order_einvoice_post_issue_copy.dart';
import 'einvoice_action_item.dart';

/// Actions returned by [showPostIssueEInvoiceActionSheet].
enum PostIssueAction { viewOfficial, documents, send }

/// State passed to [PostIssueEInvoiceActionSheet].
class PostIssueSheetState {
  const PostIssueSheetState({
    this.deliveryStatus = DeliveryDisplayState.notSent,
    this.isOfficialViewLoading = false,
    this.isDeliveryPending = false,
    this.hasSecondaryAttention = false,
  });

  final DeliveryDisplayState deliveryStatus;
  final bool isOfficialViewLoading;
  final bool isDeliveryPending;
  final bool hasSecondaryAttention;

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

/// Post-issue E-Invoice action sheet (SG02-O05 / O06).
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
        state.deliveryStatus != DeliveryDisplayState.sending;

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
                  OrderEInvoicePostIssueCopy.sheetTitle,
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              EInvoiceActionItem(
                key: const Key('action_view_official'),
                icon: VIcons.visibility,
                title: OrderEInvoicePostIssueCopy.viewOfficialTitle,
                supportingText: OrderEInvoicePostIssueCopy.viewOfficialSupporting,
                enabled: true,
                loading: state.isOfficialViewLoading,
                onTap: state.isOfficialViewLoading ? null : onViewOfficial,
              ),
              EInvoiceActionItem(
                key: const Key('action_documents'),
                icon: VIcons.fileCheck,
                title: OrderEInvoicePostIssueCopy.documentsTitle,
                supportingText: OrderEInvoicePostIssueCopy.documentsSupporting,
                enabled: isActionsEnabled,
                onTap: isActionsEnabled ? () => select(PostIssueAction.documents) : null,
              ),
              EInvoiceActionItem(
                key: const Key('action_send'),
                icon: VIcons.send,
                title: OrderEInvoicePostIssueCopy.sendTitle,
                supportingText: state.hasSecondaryAttention
                    ? OrderEInvoicePostIssueCopy.deliverySecondaryAttention
                    : OrderEInvoicePostIssueCopy.sendSupporting,
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
        label: OrderEInvoicePostIssueCopy.deliveryNotSent,
        tone: VComponentTone.neutral,
      ),
      DeliveryDisplayState.sending => const VBadge(
        label: OrderEInvoicePostIssueCopy.deliverySending,
        tone: VComponentTone.primary,
      ),
      DeliveryDisplayState.sent => const VBadge(
        label: OrderEInvoicePostIssueCopy.deliverySent,
        tone: VComponentTone.success,
      ),
      DeliveryDisplayState.failed => const VBadge(
        label: OrderEInvoicePostIssueCopy.deliverySendFailed,
        tone: VComponentTone.danger,
      ),
      DeliveryDisplayState.unknown => const VBadge(
        label: OrderEInvoicePostIssueCopy.deliveryUnknown,
        tone: VComponentTone.warning,
      ),
    };
  }
}
