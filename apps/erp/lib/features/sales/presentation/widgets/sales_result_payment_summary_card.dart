import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'package:erp/features/sales/logic/sales_transaction_result_state.dart';
import 'sales_amount_highlight_row.dart';

class SalesResultPaymentSummaryCard extends StatelessWidget {
  const SalesResultPaymentSummaryCard({
    super.key,
    required this.state,
  });

  final SalesTransactionResultState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final payment = state.payment;
    final total = payment?.orderTotal.amountMinor ?? 0;
    final paid = payment?.paidTotal.amountMinor ?? 0;
    final outstanding = payment?.outstandingTotal.amountMinor ?? 0;
    final change = paid > total ? paid - total : 0;
    final dueAt = payment?.dueAt;

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VText(
            'Tóm tắt thanh toán',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap(VSpacing.space2),

          SalesAmountHighlightRow(
            label: 'Tổng đơn',
            amountMinor: total,
            tone: VComponentTone.primary,
            amountVariant: VTextVariant.headingH4Mono,
          ),
          // Đã thanh toán row
          SalesAmountHighlightRow(
            label: 'Đã thanh toán',
            amountMinor: paid,
            tone: VComponentTone.neutral,
            labelVariant: VTextVariant.bodySmall,
            amountVariant: VTextVariant.headingH4Mono,
          ),
          if (outstanding > 0) ...[
            SalesAmountHighlightRow(
              label: 'Còn phải thu',
              amountMinor: outstanding,
              tone: VComponentTone.warning,
              backgroundColor: Colors.transparent,
              labelVariant: VTextVariant.bodySmall,
              amountVariant: VTextVariant.headingH4Mono,
            ),
          ],
          // Tiền thừa row (if any)
          if (change > 0) ...[
            SalesAmountHighlightRow(
              label: 'Tiền thừa',
              amountMinor: change,
              tone: VComponentTone.neutral,
              labelVariant: VTextVariant.bodySmall,
              amountVariant: VTextVariant.headingH4Mono,
            ),
          ],

          // Hẹn thanh toán row (if any)
          if (dueAt != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.space3,
                VSpacing.space3,
                VSpacing.space3,
                VSpacing.space2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VText(
                    'Hẹn thanh toán',
                    variant: VTextVariant.bodySmall,
                    color: colors.textPrimary,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  VText(
                    VDateTime.calendarDate(dueAt),
                    variant: VTextVariant.bodyDefault,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
