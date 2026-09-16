import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../bloc/invoice_delivery_history_state.dart';
import '../../models/invoice_delivery_history_vm.dart';
import '../../support/order_invoice_delivery_copy.dart';

/// App-owned SG07-D01 delivery history body (VM/state only — no mediator).
class InvoiceDeliveryHistoryView extends StatelessWidget {
  const InvoiceDeliveryHistoryView({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final InvoiceDeliveryHistoryState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || state.status == InvoiceDeliveryHistoryStatus.initial) {
      return const Center(child: VLoading());
    }

    if (state.status == InvoiceDeliveryHistoryStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: VEmptyState(
            key: const Key('history_error_state'),
            tone: VComponentTone.danger,
            bordered: true,
            backgroundColor: context.vColors.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VEmptyHeader(
                  children: [
                    const VEmptyMedia(icon: VIcons.error),
                    const VEmptyTitle(OrderInvoiceDeliveryCopy.historyLoadFailed),
                    VEmptyDescription(
                      state.errorMessage ?? OrderInvoiceDeliveryCopy.historyLoadFailed,
                    ),
                  ],
                ),
                const VGap(VSpacing.space2),
                VEmptyContent(
                  child: VButton(
                    key: const Key('action_retry_history'),
                    label: OrderInvoiceDeliveryCopy.historyRetry,
                    onPressed: onRetry,
                    variant: VButtonVariant.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(VSpacing.space4),
          child: VEmptyState(
            key: Key('history_empty_state'),
            bordered: true,
            child: VEmptyHeader(
              children: [
                VEmptyMedia(icon: VIcons.inbox),
                VEmptyTitle(OrderInvoiceDeliveryCopy.historyEmpty),
              ],
            ),
          ),
        ),
      );
    }

    final colors = context.vColors;
    return ListView(
      padding: const EdgeInsets.all(VSpacing.space4),
      children: [
        VText(
          OrderInvoiceDeliveryCopy.historySectionTitle,
          variant: VTextVariant.headingH4,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.md(),
        VCard(
          padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
          child: Column(
            children: [
              for (var i = 0; i < state.rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.borderDefault),
                _HistoryRow(row: state.rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.row});

  final InvoiceDeliveryHistoryRowVm row;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final local = row.occurredAt;
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    return Padding(
      key: Key('history_row_${row.deliveryId}'),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  '${row.statusLabel} · ${row.recipientEmail}',
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                VText(
                  '$date · $time · ${row.actorLabel}',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          VBadge(label: row.statusLabel, tone: row.tone),
        ],
      ),
    );
  }
}
