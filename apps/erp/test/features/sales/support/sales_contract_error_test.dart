// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';

import 'sales_contract_error.dart';
import 'sales_contract_fixtures.dart';

void main() {
  test('PERMISSION_DENIED đổi thành NO_PERMISSION', () {
    expect(salesContractError('PERMISSION_DENIED').code, 'NO_PERMISSION');
  });

  test('mã khác giữ nguyên, serverMessage là message', () {
    final e = salesContractError('STALE_VERSION', message: 'cũ');
    expect(e.code, 'STALE_VERSION');
    expect(e.serverMessage, 'cũ');
  });

  test('blockers là SalesBlockerDto đổi sang map', () {
    final e = salesContractError(
      'X',
      details: {
        'blockers': [SalesBlockerDto(code: 'X', message: 'm', field: 'f')],
      },
    );
    expect(e.details, {
      'blockers': [
        {'code': 'X', 'message': 'm', 'field': 'f'},
      ],
    });
  });

  test('details thường giữ nguyên', () {
    expect(salesContractError('X', details: {'k': 1}).details, {'k': 1});
  });

  test('details rỗng thì null', () {
    expect(salesContractError('X').details, isNull);
  });

  // Xoá ở 8-C Task 3 Step 0: sau khi đổi import, DTO của app khác kiểu DTO của module.
  group('salesFixture khớp SalesFakeContractFixtureFactory', () {
    test('AvailablePostSaleActionsDto', () {
      final a = salesFixture<AvailablePostSaleActionsDto>();
      final b =
          SalesFakeContractFixtureFactory.create('GetAvailablePostSaleActionsQuery')
              as AvailablePostSaleActionsDto;
      expect([a.canCancel, a.canReturnExchange], [b.canCancel, b.canReturnExchange]);
    });

    test('CheckoutResultDto', () {
      final a = salesFixture<CheckoutResultDto>();
      final b = SalesFakeContractFixtureFactory.create('GetCheckoutResultQuery') as CheckoutResultDto;
      expect(
        [a.idempotencyKey, a.salesOrderId, a.salesOrderVersion, a.status],
        [b.idempotencyKey, b.salesOrderId, b.salesOrderVersion, b.status],
      );
    });

    test('SalesOrderResultDto', () {
      final a = salesFixture<SalesOrderResultDto>();
      final b = SalesFakeContractFixtureFactory.create('GetSalesOrderQuery') as SalesOrderResultDto;
      List<Object?> sig(SalesOrderResultDto d) => [
        d.order.salesOrderId,
        d.order.orderNumber,
        d.order.version,
        d.order.lifecycleStatus,
        d.order.lockStatus,
        d.order.total.amountMinor,
        d.committedAt,
        d.store.storeId,
        d.store.storeCode,
        d.store.displayName,
        d.seller.actorId,
        d.seller.displayName,
        d.customer?.customerId,
        d.customer?.displayName,
        d.customer?.phoneNumber,
      ];
      expect(sig(a), sig(b));
    });

    test('SalesOrderPaymentSummaryDto', () {
      final a = salesFixture<SalesOrderPaymentSummaryDto>();
      final b =
          SalesFakeContractFixtureFactory.create('GetSalesOrderPaymentSummaryQuery')
              as SalesOrderPaymentSummaryDto;
      List<Object?> sig(SalesOrderPaymentSummaryDto d) => [
        d.status,
        d.orderTotal.amountMinor,
        d.paidTotal.amountMinor,
        d.outstandingTotal.amountMinor,
        d.dueAt,
      ];
      expect(sig(a), sig(b));
    });

    test('SalesOrderSettlementDto', () {
      final a = salesFixture<SalesOrderSettlementDto>();
      final b =
          SalesFakeContractFixtureFactory.create('GetSalesOrderSettlementQuery')
              as SalesOrderSettlementDto;
      List<Object?> sig(SalesOrderSettlementDto d) => [
        d.settlementId,
        d.salesOrderId,
        d.version,
        d.status,
        d.orderTotal.amountMinor,
        d.paidTotal.amountMinor,
        d.refundedTotal.amountMinor,
        d.outstanding.amountMinor,
        d.dueAt,
      ];
      expect(sig(a), sig(b));
    });

    test('SalesPaymentTransactionsDto', () {
      final a = salesFixture<SalesPaymentTransactionsDto>();
      final b =
          SalesFakeContractFixtureFactory.create('GetSalesOrderPaymentTransactionsQuery')
              as SalesPaymentTransactionsDto;
      List<Object?> sig(SalesPaymentTransactionsDto d) => [
        d.page.hasMore,
        d.page.nextCursor,
        for (final t in d.page.items) ...[
          t.transactionId,
          t.method,
          t.amount.amountMinor,
          t.status,
          t.recordedAt,
          t.transactionType,
          t.direction,
        ],
      ];
      expect(sig(a), sig(b));
    });

    test('SalesOrderTimelineDto', () {
      final a = salesFixture<SalesOrderTimelineDto>();
      final b =
          SalesFakeContractFixtureFactory.create('GetSalesOrderTimelineQuery')
              as SalesOrderTimelineDto;
      List<Object?> sig(SalesOrderTimelineDto d) => [
        d.salesOrderId,
        for (final e in d.entries) ...[
          e.eventId,
          e.eventType,
          e.occurredAt,
          e.sourceVersion,
          e.actor?.actorId,
          e.actor?.displayName,
          e.description,
          e.amount?.amountMinor,
        ],
      ];
      expect(sig(a), sig(b));
    });

    test('SalesOrderReturnSummaryDto', () {
      final a = salesFixture<SalesOrderReturnSummaryDto>();
      final b =
          SalesFakeContractFixtureFactory.create('GetSalesOrderReturnSummaryQuery')
              as SalesOrderReturnSummaryDto;
      expect([a.salesOrderId, a.returns.length], [b.salesOrderId, b.returns.length]);
    });

    test('ReturnExchangeValuationDto', () {
      final a = salesFixture<ReturnExchangeValuationDto>();
      final b =
          SalesFakeContractFixtureFactory.create('EvaluateReturnPricingImpactQuery')
              as ReturnExchangeValuationDto;
      expect(_valuationSig(a), _valuationSig(b));
    });

    test('ReturnExchangeDetailDto', () {
      final a = salesFixture<ReturnExchangeDetailDto>();
      final b =
          SalesFakeContractFixtureFactory.create('GetReturnExchangeDetailQuery')
              as ReturnExchangeDetailDto;
      List<Object?> sig(ReturnExchangeDetailDto d) => [
        d.result.returnExchangeId,
        d.result.salesOrderId,
        d.result.version,
        d.result.status,
        d.referenceNumber,
        d.entrySource,
        d.createdAt,
        d.confirmedByActorId,
        d.confirmedAt,
        d.completedAt,
        d.lines.length,
        ..._valuationSig(d.valuation),
        ..._planSig(d.settlementPlan),
        d.completionReady,
      ];
      expect(sig(a), sig(b));
    });

    test('kiểu chưa hỗ trợ ném UnsupportedError', () {
      expect(() => salesFixture<SalesBlockerDto>(), throwsUnsupportedError);
    });
  });
}

List<Object?> _planSig(ReturnExchangeSettlementPlanDto p) => [
  p.currencyCode,
  p.netDifferenceMinor,
  p.collectAmountMinor,
  p.refundAmountMinor,
  p.receivableCreateAmountMinor,
  p.receivableReverseAmountMinor,
  p.processedCollectMinor,
  p.processedRefundMinor,
  p.pendingReceivableCreateMinor,
  p.pendingReceivableReverseMinor,
  p.remainderCollectMinor,
  p.remainderRefundMinor,
  p.sourceOrderVersion,
  p.sourceSettlementVersion,
];

List<Object?> _valuationSig(ReturnExchangeValuationDto v) => [
  v.returnValue.amountMinor,
  v.exchangeValue.amountMinor,
  v.settlementDifference.amountMinor,
  ..._planSig(v.settlementPlan),
  v.sourceOrderVersion,
  v.pricingSourceVersion,
];
