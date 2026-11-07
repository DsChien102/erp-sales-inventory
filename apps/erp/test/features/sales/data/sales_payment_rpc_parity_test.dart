// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sales_checkout_parity_expectations.dart';

class _RecordingRpc implements SupabaseRpc {
  final calls = <({String schema, String fn, Map<String, dynamic>? params})>[];
  Object? result;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add((schema: schema, fn: fn, params: params));
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('new', () {
    late _RecordingRpc rpc;
    late SalesPaymentRepository payment;
    late SalesOrderRepository order;

    setUp(() {
      rpc = _RecordingRpc();
      payment = SalesPaymentRepository(
        rpc: rpc,
        tenantId: () async => checkoutTenantId,
        actorId: () async => checkoutActorId,
        newId: () => checkoutQueryId,
      );
      order = SalesOrderRepository(
        rpc: rpc,
        tenantId: () async => checkoutTenantId,
        actorId: () async => checkoutActorId,
        newId: () => checkoutQueryId,
      );
    });

    void expectCall(String fn, Map<String, dynamic> params) {
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, fn);
      expect(rpc.calls.single.params, equals(params));
    }

    test('params_summary', () async {
      rpc.result = summaryJson();
      final dto = await payment.getSummary(salesOrderId: 'order-1', expectedSourceVersion: 7);
      expectCall('get_sales_order_payment_summary', expectedSummaryParams(version: 7));
      expectSummary(dto);
    });

    test('summary_omits_expected_version_when_null', () async {
      rpc.result = summaryJson();
      await payment.getSummary(salesOrderId: 'order-1');
      expectCall('get_sales_order_payment_summary', expectedSummaryParams());
      expect(rpc.calls.single.params, isNot(contains('p_expected_source_version')));
    });

    test('params_settlement', () async {
      rpc.result = settlementJson();
      final dto = await payment.getSettlement(salesOrderId: 'order-1', expectedSourceVersion: 7);
      expectCall('get_sales_order_settlement', expectedSettlementParams());
      expectSettlement(dto);
    });

    test('settlement_sends_unprefixed_keys', () async {
      rpc.result = settlementJson();
      await payment.getSettlement(salesOrderId: 'order-1');
      final params = rpc.calls.single.params!;
      expect(params.keys, isNot(contains('p_query_id')));
      expect(params.keys.every((k) => !k.startsWith('p_')), isTrue);
      // expected_source_version luôn có, kể cả null
      expect(params, containsPair('expected_source_version', null));
    });

    test('params_transactions', () async {
      rpc.result = transactionsJson();
      final dto = await payment.getTransactions(
        salesOrderId: 'order-1',
        expectedSourceVersion: 7,
        cursor: 'cur-1',
        pageSize: 10,
      );
      expectCall('get_sales_order_payment_transactions', expectedTransactionsParams());
      expectTransactions(dto);
    });

    test('transactions_default_page_size_25', () async {
      rpc.result = transactionsJson();
      await payment.getTransactions(salesOrderId: 'order-1');
      expect(rpc.calls.single.params!['page_size'], 25);
      expect(rpc.calls.single.params!['cursor'], isNull);
    });

    test('params_get_order', () async {
      rpc.result = orderResultJson();
      final dto = await order.get(salesOrderId: 'order-1');
      expectCall('get_sales_order', expectedGetOrderParams());
      expectOrderResult(dto);
    });

    test('get_order_has_no_expected_version_key', () async {
      rpc.result = orderResultJson();
      await order.get(salesOrderId: 'order-1');
      expect(rpc.calls.single.params, isNot(contains('p_expected_source_version')));
    });
  });
}
