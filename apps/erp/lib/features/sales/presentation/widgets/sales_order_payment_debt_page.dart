import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/sales_order_settlement/sales_order_payment_vm.dart';
import 'sales_amount_highlight_row.dart';
import 'sales_label_highlight_row.dart';

class SalesOrderPaymentDebtPage extends StatelessWidget {
  const SalesOrderPaymentDebtPage({
    super.key,
    required this.orderNumber,
    required this.customerName,
    required this.payment,
  });

  final String orderNumber;
  final String customerName;
  final SalesOrderPaymentVm payment;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPageScaffold(
      key: const Key('wgt_sg08_payment_debt_page'),
      title: 'Thanh toán & công nợ',
      showBackButton: true,
      body: SingleChildScrollView(
        child: VPagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VGap(VSpacing.space4),
              VText(
                '#$orderNumber · $customerName',
                variant: VTextVariant.bodyDefaultMono,
                color: colors.textSecondary,
                key: const Key('wgt_sg08_payment_debt_context'),
              ),
              const VGap(VSpacing.space4),
              _CurrentStatusCard(payment: payment),
              if (payment.originalOrderBreakdown case final original?) ...[
                const VGap(VSpacing.space2),
                _OriginalOrderCard(breakdown: original),
              ],
              for (final slip in payment.returnSlipBreakdowns) ...[
                const VGap(VSpacing.space2),
                _ReturnSlipCard(breakdown: slip),
              ],
              if (payment.transactions.isNotEmpty) ...[
                const VGap(VSpacing.space2),
                _TransactionListCard(transactions: payment.transactions),
              ],
              const VGap(VSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({required this.payment});

  final SalesOrderPaymentVm payment;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      key: const Key('wgt_sg08_payment_debt_current_status'),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VText(
            'Tình trạng hiện tại',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.cozy(),
          SalesLabelHighlightRow(
            key: const Key('wgt_sg08_payment_debt_settlement_label'),
            label: 'Trạng thái',
            value: payment.settlementLabel,
            tone: VComponentTone.neutral,
          ),
          SalesAmountHighlightRow(
            label: 'Tổng đơn',
            amountMinor: payment.orderTotalMinor,
          ),
          ..._paidMethodRows(payment),
          if (payment.offsetMinor > 0)
            SalesAmountHighlightRow(
              key: const Key('wgt_sg09b_offset_total'),
              label: 'Đã cấn trừ',
              amountMinor: payment.offsetMinor,
              tone: VComponentTone.neutral,
            ),
          SalesAmountHighlightRow(
            label: 'Còn phải thu',
            amountMinor: payment.outstandingMinor,
            tone: VComponentTone.warning,
            backgroundColor: Colors.transparent,
          ),
          if (payment.dueDateFormatted != null) ...[
            SalesLabelHighlightRow(
              label: 'Hẹn thanh toán',
              value: payment.dueDateFormatted!,
              tone: VComponentTone.neutral,
            ),
          ],
        ],
      ),
    );
  }
}

class _OriginalOrderCard extends StatelessWidget {
  const _OriginalOrderCard({required this.breakdown});

  final SalesOrderPaymentOriginalBreakdownVm breakdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      key: const Key('wgt_sg08_payment_debt_original_order'),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VText(
            'Từ đơn hàng gốc',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SalesAmountHighlightRow(
            label: 'Tổng đơn',
            amountMinor: breakdown.orderTotalMinor,
          ),
          if (breakdown.paidCashMinor > 0) ...[
            SalesAmountHighlightRow(
              label: 'Đã thanh toán (TM)',
              amountMinor: breakdown.paidCashMinor,
              tone: VComponentTone.neutral,
            ),
          ],
          if (breakdown.paidBankMinor > 0) ...[
            SalesAmountHighlightRow(
              label: 'Đã thanh toán (CK)',
              amountMinor: breakdown.paidBankMinor,
              tone: VComponentTone.neutral,
            ),
          ],
          SalesAmountHighlightRow(
            label: 'Còn phải thu',
            amountMinor: breakdown.outstandingMinor,
            tone: VComponentTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _ReturnSlipCard extends StatelessWidget {
  const _ReturnSlipCard({required this.breakdown});

  final SalesOrderPaymentReturnSlipBreakdownVm breakdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      key: Key('wgt_sg08_payment_debt_return_${breakdown.slipNumber}'),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Từ phiếu đổi/trả #${breakdown.slipNumber}',
            variant: VTextVariant.bodyDefault,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.md(),
          SalesAmountHighlightRow(
            label: 'Khách trả thêm',
            amountMinor: breakdown.customerPaysExtraMinor,
            tone: VComponentTone.neutral,
          ),
          if (breakdown.paidCashExtraMinor > 0) ...[
            const VGap.md(),
            SalesAmountHighlightRow(
              label: 'Đã thu thêm (TM)',
              amountMinor: breakdown.paidCashExtraMinor,
              tone: VComponentTone.neutral,
            ),
          ],
          if (breakdown.paidBankExtraMinor > 0) ...[
            const VGap.md(),
            SalesAmountHighlightRow(
              label: 'Đã thu thêm (CK)',
              amountMinor: breakdown.paidBankExtraMinor,
              tone: VComponentTone.neutral,
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionListCard extends StatelessWidget {
  const _TransactionListCard({required this.transactions});

  final List<SalesOrderPaymentTransactionVm> transactions;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      key: const Key('wgt_sg08_payment_debt_transactions'),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VText(
            'Giao dịch',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          for (final tx in transactions) _transactionRow(context, tx),
        ],
      ),
    );
  }

  Widget _transactionRow(BuildContext context, SalesOrderPaymentTransactionVm tx) {
    final row = SalesAmountHighlightRow(
      label: tx.kindLabel == null ? tx.methodLabel : '${tx.kindLabel} · ${tx.methodLabel}',
      amountMinor: tx.amountMinor,
      tone: VComponentTone.neutral,
    );
    final target = tx.counterpartSalesOrderId;
    if (target == null) return row;
    // Giao dịch cấn trừ: chạm để sang đơn đối ứng.
    return InkWell(
      key: Key('wgt_sg09b_offset_tx_${tx.transactionId}'),
      onTap: () => context.push('/sales/orders/$target'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
        child: Row(
          children: [
            Expanded(child: row),
            VIcon(icon: VIcons.chevronRight, size: 20, color: context.vColors.textMuted),
          ],
        ),
      ),
    );
  }
}

List<Widget> _paidMethodRows(SalesOrderPaymentVm payment) {
  final rows = <Widget>[];
  if (payment.paidCashAmountMinor > 0) {
    rows.add(
      SalesAmountHighlightRow(
        label: 'Đã thanh toán (TM)',
        amountMinor: payment.paidCashAmountMinor,
        tone: VComponentTone.neutral,
      ),
    );
  }
  if (payment.paidBankAmountMinor > 0) {
    rows.add(
      SalesAmountHighlightRow(
        label: 'Đã thanh toán (CK)',
        amountMinor: payment.paidBankAmountMinor,
        tone: VComponentTone.neutral,
      ),
    );
  }
  if (payment.paidCashAmountMinor <= 0 && payment.paidBankAmountMinor <= 0) {
    rows.add(
      SalesAmountHighlightRow(
        label: 'Đã thanh toán',
        amountMinor: payment.paidTotalMinor,
      ),
    );
  }
  return rows;
}
