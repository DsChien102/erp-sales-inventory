import 'package:erp/features/sales/presentation/models/sales_order/sales_order_detail_vm.dart';
import 'package:erp/features/sales/presentation/support/sales_order_detail_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart' as app;

void main() {
  group('SalesOrderDetailMapper payment direction', () {
    test('same amount with opposite direction does not both count as collected', () {
      const amount = 60000;
      final summary = app.SalesOrderPaymentSummaryDto(
        status: app.SalesSettlementStatus.partiallyRefunded,
        orderTotal: const app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        paidTotal: const app.MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
        outstandingTotal: const app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        refundedTotal: const app.MoneyDto(amountMinor: amount, currencyCode: 'VND'),
        netCollectedTotal: const app.MoneyDto(amountMinor: 60000, currencyCode: 'VND'),
        originalPayableTotal: const app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        adjustmentTotal: const app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        collectedCash: const app.MoneyDto(amountMinor: 180000, currencyCode: 'VND'),
        collectedBank: const app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        dueAt: DateTime.utc(2026, 9, 9),
        originalOrder: const app.SalesOrderPaymentOriginalBreakdownDto(
          orderTotal: app.MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
          paidCash: app.MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
          paidBank: app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          outstanding: app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        ),
      );
      final settlement = app.SalesOrderSettlementDto(
        settlementId: 'settlement-1',
        salesOrderId: 'order-1',
        version: 3,
        status: app.SalesSettlementStatus.partiallyRefunded,
        orderTotal: const app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        paidTotal: const app.MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
        refundedTotal: const app.MoneyDto(amountMinor: amount, currencyCode: 'VND'),
        outstanding: const app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      );
      final transactions = app.SalesPaymentTransactionsDto(
        page: app.OpaqueCursorPageDto<app.SalesPaymentTransactionDto>(
          items: [
            _tx(
              id: 'collect-checkout',
              amount: 120000,
              type: app.SalesPaymentTransactionType.collection,
              direction: app.SalesPaymentDirection.inflow,
              sourceContext: 'checkout',
              actorId: 'seller-1',
            ),
            _tx(
              id: 'collect-extra',
              amount: 60000,
              type: app.SalesPaymentTransactionType.collection,
              direction: app.SalesPaymentDirection.inflow,
              sourceContext: 'return_exchange',
              actorId: 'seller-1',
            ),
            _tx(
              id: 'refund-60',
              amount: amount,
              type: app.SalesPaymentTransactionType.refund,
              direction: app.SalesPaymentDirection.outflow,
              sourceContext: 'return_exchange',
              actorId: 'seller-2',
            ),
          ],
          hasMore: false,
        ),
      );

      final vm = SalesOrderDetailMapper.toPaymentVm(
        summary: summary,
        settlement: settlement,
        transactions: transactions,
      );

      expect(vm.paidCashAmountMinor, 180000);
      expect(vm.paidBankAmountMinor, 0);
      expect(vm.paidTotalMinor, 120000);
      expect(vm.outstandingMinor, 0);
      expect(vm.settlementStatus, SalesSettlementStatus.partiallyRefunded);
      expect(vm.settlementLabel, 'Hoàn một phần');
      expect(vm.dueDateFormatted, '09/09/2026');
      expect(vm.originalOrderBreakdown?.paidCashMinor, 120000);
      expect(vm.transactions.map((tx) => tx.kindLabel).toList(), [
        'Thu tiền',
        'Thu tiền',
        'Hoàn tiền',
      ]);
      expect(vm.transactions.last.amountMinor, amount);
      expect(vm.transactions.last.actorId, 'seller-2');
      expect(vm.transactions.first.actorId, 'seller-1');
    });

    test('refunded status is not folded into fully paid', () {
      final vm = SalesOrderDetailMapper.toPaymentVm(
        summary: const app.SalesOrderPaymentSummaryDto(
          status: app.SalesSettlementStatus.refunded,
          orderTotal: app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          paidTotal: app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          outstandingTotal: app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          collectedCash: app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          collectedBank: app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        ),
        settlement: const app.SalesOrderSettlementDto(
          settlementId: 'settlement-1',
          salesOrderId: 'order-1',
          version: 2,
          status: app.SalesSettlementStatus.refunded,
          orderTotal: app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          paidTotal: app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          refundedTotal: app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          outstanding: app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        ),
        transactions: app.SalesPaymentTransactionsDto(
          page: app.OpaqueCursorPageDto<app.SalesPaymentTransactionDto>(
            items: const [],
            hasMore: false,
          ),
        ),
      );

      expect(vm.settlementStatus, SalesSettlementStatus.refunded);
      expect(vm.settlementLabel, 'Đã hoàn');
    });
  });
}

app.SalesPaymentTransactionDto _tx({
  required String id,
  required int amount,
  required app.SalesPaymentTransactionType type,
  required app.SalesPaymentDirection direction,
  required String sourceContext,
  required String actorId,
}) {
  return app.SalesPaymentTransactionDto(
    transactionId: id,
    method: app.SalesPaymentMethod.cash,
    amount: app.MoneyDto(amountMinor: amount, currencyCode: 'VND'),
    status: app.SalesPaymentStatus.confirmed,
    recordedAt: DateTime.utc(2026, 9, 9, 4, 0),
    transactionType: type,
    direction: direction,
    sourceContext: sourceContext,
    actorId: actorId,
  );
}
