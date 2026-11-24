import 'dart:convert';

import 'package:erp/features/sales/data/mappers/return_exchange_json.dart';
import 'package:erp/features/sales/data/mappers/sales_payment_json.dart';
import 'package:erp/features/sales/data/mappers/sales_receipt_json.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_attempt_factory.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sales_order_inquiry_parity_expectations.dart';
import 'sales_post_sale_parity_expectations.dart';

Map<String, dynamic> _m(int v) => {'amountMinor': v, 'currencyCode': 'VND'};

Map<String, dynamic> _planWithOffset() {
  final plan = Map<String, dynamic>.from(
    sampleValuationJson()['settlementPlan'] as Map<String, dynamic>,
  );
  plan['offsetAmountMinor'] = 500000;
  plan['offsetCandidates'] = [
    {
      'salesOrderId': 'o2',
      'orderCode': 'DH-002',
      'completedAt': '2026-11-01T03:00:00Z',
      'outstandingMinor': 2000000,
      'offsetAmountMinor': 500000,
      'dueDate': '2026-11-16',
      'overdueDays': 3,
      'settlementVersion': 4,
    },
  ];
  return plan;
}

void main() {
  test('settlement plan parses offset fields', () {
    final json = sampleValuationJson()..['settlementPlan'] = _planWithOffset();
    final plan = ReturnExchangeJson.valuationFromJson(json).settlementPlan;
    expect(plan.offsetAmountMinor, 500000);
    expect(plan.offsetCandidates.single.orderCode, 'DH-002');
    expect(plan.offsetCandidates.single.outstandingMinor, 2000000);
    expect(plan.offsetCandidates.single.dueDate, DateTime(2026, 11, 16));
    expect(plan.offsetCandidates.single.overdueDays, 3);
  });

  test('settlement plan without offset keys still parses', () {
    final plan = ReturnExchangeJson.valuationFromJson(
      sampleValuationJson(),
    ).settlementPlan;
    expect(plan.offsetAmountMinor, 0);
    expect(plan.offsetCandidates, isEmpty);
  });

  test('confirm params send offset_target_order_ids', () {
    final params = ReturnExchangeJson.confirmParams(
      request: const ReturnExchangeConfirmRequest(
        commandId: 'c',
        returnExchangeId: 'r',
        idempotencyKey: 'k',
        payloadHash: 'h',
        correlationId: 'x',
        expectedVersion: 4,
        offsetTargetOrderIds: ['o2', 'o3'],
      ),
      tenantId: 't',
      actorId: 'a',
    );
    expect(params['offset_target_order_ids'], ['o2', 'o3']);
  });

  test('confirm hash includes offset targets', () {
    String hash(List<String> ids) =>
        SalesReturnExchangeAttemptFactory(newAttemptId: () => 'id')
            .confirm(
              tenantId: 't',
              actorId: 'a',
              returnExchangeId: 'r',
              expectedVersion: 4,
              correlationId: 'x',
              offsetTargetOrderIds: ids,
            )
            .payloadHash;
    expect(hash(['o2']), isNot(hash([])));
    expect(hash(['o2']), hash(['o2']));
    expect(hash(['o2']), isNot(hash(['o2', 'o3'])));
  });

  test('offset is never sent by the app', () {
    expect(
      () => ReturnExchangeJson.confirmParams(
        request: const ReturnExchangeConfirmRequest(
          commandId: 'c',
          returnExchangeId: 'r',
          idempotencyKey: 'k',
          payloadHash: 'h',
          correlationId: 'x',
          expectedVersion: 4,
          paymentMethod: SalesPaymentMethod.offset,
        ),
        tenantId: 't',
        actorId: 'a',
      ),
      throwsArgumentError,
    );
  });

  test('parses offset method in transactions', () {
    final page = SalesPaymentJson.transactionsFromJson({
      'items': [
        {
          'transactionId': 'tx-1',
          'method': 'offset',
          'amount': _m(500000),
          'status': 'confirmed',
          'recordedAt': '2026-11-19T02:00:00Z',
          'transactionType': 'refund',
          'direction': 'outflow',
          'counterpartOrderCode': 'DH-002',
          'counterpartSalesOrderId': 'o2',
          'customerCollectionId': null,
        },
      ],
      'hasMore': false,
    });
    final tx = page.page.items.single;
    expect(tx.method, SalesPaymentMethod.offset);
    expect(tx.counterpartOrderCode, 'DH-002');
    expect(tx.counterpartSalesOrderId, 'o2');
  });

  test('payment summary parses collectedOffset / refundedOffset', () {
    final base = <String, dynamic>{
      'status': 'partiallyPaid',
      'orderTotal': _m(1000000),
      'paidTotal': _m(400000),
      'refundedTotal': _m(0),
      'netCollectedTotal': _m(400000),
      'originalPayableTotal': _m(1000000),
      'adjustmentTotal': _m(0),
      'collectedCash': _m(300000),
      'collectedBank': _m(100000),
      'outstandingTotal': _m(600000),
      'dueAt': null,
    };
    final without = SalesPaymentJson.paymentSummaryFromJson(base);
    expect(without.collectedOffset.amountMinor, 0);
    expect(without.refundedOffset.amountMinor, 0);
    final withOffset = SalesPaymentJson.paymentSummaryFromJson({
      ...base,
      'collectedOffset': _m(200000),
      'refundedOffset': _m(500000),
    });
    expect(withOffset.collectedOffset.amountMinor, 200000);
    expect(withOffset.refundedOffset.amountMinor, 500000);
  });

  test('parses offset method in receipt', () {
    final json = jsonDecode(
      jsonEncode(sampleReceiptJson()).replaceFirst('"method":"cash"', '"method":"offset"'),
    ) as Map<String, dynamic>;
    final receipt = SalesReceiptJson.salesReceiptFromJson(json);
    expect(receipt.document.payments.single.method, SalesPaymentMethod.offset);
  });
}
