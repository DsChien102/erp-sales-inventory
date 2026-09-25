import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/sales_order/sales_checkout_vm.dart';
import 'sales_amount_highlight_row.dart';

/// Highlighted "Công nợ phát sinh" card for the checkout screen. Shows the
/// receivable that will be recorded from the remaining unpaid amount. Uses the
/// success tone for both states; only the amount and description change.
class SalesCheckoutReceivableCard extends StatelessWidget {
  const SalesCheckoutReceivableCard({
    super.key,
    required this.vm,
    required this.onDueDateSelected,
    this.enabled = true,
  });

  final SalesCheckoutVm vm;
  final ValueChanged<DateTime> onDueDateSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final receivableMinor = vm.remainingReceivableMinor;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SalesAmountHighlightRow(
            label: 'Công nợ phát sinh',
            amountMinor: receivableMinor,
            amountKey: const Key('txt_sg05_receivable_amount'),
          ),
          if (receivableMinor > 0) ...[
            const VGap.md(),
            VDatePicker(
              key: const Key('input_sg05_receivable_due_date'),
              label: 'Ngày hẹn thanh toán',
              required: true,
              hintText: 'Chọn ngày hẹn',
              value: vm.dueDate,
              enabled: enabled,
              firstDate: today,
              lastDate: DateTime(today.year + 5, today.month, today.day),
              onChanged: onDueDateSelected,
            ),
            const VGap.xs(),
            VText(
              'Bắt buộc khi phát sinh công nợ.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ] else ...[
            const VGap.xs(),
            VText(
              'Không phát sinh công nợ.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}
