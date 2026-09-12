import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('SupabaseSalesOrderReadGateway', () {
    test('S13 maps the committed order-result envelope with UTC timestamps', () async {
      final rpc = _FakeRpcClient(response: _orderResultJson());
      final gateway = SupabaseSalesOrderReadGateway(rpcClient: rpc);

      final dto = await gateway.getSalesOrder(_orderQuery());

      expect(rpc.lastProcedure, 'get_sales_order');
      expect(rpc.lastParams?['p_sales_order_id'], 'order-1');
      expect(rpc.lastParams, isNot(contains('sales_order_id')));
      expect(dto.order.lifecycleStatus, SalesOrderLifecycleStatus.completed);
      expect(dto.committedAt, DateTime.utc(2026, 8, 12, 2, 41));
      expect(dto.store.storeCode, 'HCM-01');
      expect(dto.seller.displayName, 'Minh Anh');
      expect(dto.customer?.displayName, 'Nguyen Van An');
      expect(dto.order.total.currencyCode, 'VND');
    });

    test('S13 payment summary maps money totals and a nullable due date', () async {
      final rpc = _FakeRpcClient(
        response: {
          'status': 'partiallyPaid',
          'orderTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
          'paidTotal': {'amountMinor': 400000, 'currencyCode': 'VND'},
          'refundedTotal': {'amountMinor': 0, 'currencyCode': 'VND'},
          'netCollectedTotal': {'amountMinor': 400000, 'currencyCode': 'VND'},
          'originalPayableTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
          'adjustmentTotal': {'amountMinor': 0, 'currencyCode': 'VND'},
          'collectedCash': {'amountMinor': 400000, 'currencyCode': 'VND'},
          'collectedBank': {'amountMinor': 0, 'currencyCode': 'VND'},
          'outstandingTotal': {'amountMinor': 600000, 'currencyCode': 'VND'},
          'dueAt': null,
        },
      );
      final gateway = SupabaseSalesOrderReadGateway(rpcClient: rpc);

      final dto = await gateway.getPaymentSummary(
        GetSalesOrderPaymentSummaryQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(rpc.lastProcedure, 'get_sales_order_payment_summary');
      expect(dto.status, SalesSettlementStatus.partiallyPaid);
      expect(dto.outstandingTotal.amountMinor, 600000);
      expect(dto.orderTotal.currencyCode, dto.paidTotal.currencyCode);
      expect(dto.dueAt, isNull);
      expect(dto.refundedTotal?.amountMinor, 0);
      expect(dto.netCollectedTotal?.amountMinor, 400000);
      expect(dto.collectedCash?.amountMinor, 400000);
      expect(dto.originalOrder, isNull);
    });

    test('S13 payment summary maps originalOrder breakdown when provided', () async {
      final rpc = _FakeRpcClient(
        response: {
          'status': 'paid',
          'orderTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
          'paidTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
          'refundedTotal': {'amountMinor': 0, 'currencyCode': 'VND'},
          'netCollectedTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
          'originalPayableTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
          'adjustmentTotal': {'amountMinor': 0, 'currencyCode': 'VND'},
          'collectedCash': {'amountMinor': 400000, 'currencyCode': 'VND'},
          'collectedBank': {'amountMinor': 600000, 'currencyCode': 'VND'},
          'outstandingTotal': {'amountMinor': 0, 'currencyCode': 'VND'},
          'dueAt': '2026-08-30',
          'originalOrder': {
            'orderTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
            'paidCash': {'amountMinor': 400000, 'currencyCode': 'VND'},
            'paidBank': {'amountMinor': 600000, 'currencyCode': 'VND'},
            'outstanding': {'amountMinor': 0, 'currencyCode': 'VND'},
          },
        },
      );
      final gateway = SupabaseSalesOrderReadGateway(rpcClient: rpc);

      final dto = await gateway.getPaymentSummary(
        GetSalesOrderPaymentSummaryQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(dto.originalOrder, isNotNull);
      expect(dto.originalOrder!.paidCash.amountMinor, 400000);
      expect(dto.originalOrder!.paidBank.amountMinor, 600000);
      expect(dto.originalOrder!.orderTotal.amountMinor, 1000000);
      expect(dto.originalOrder!.outstanding.amountMinor, 0);
      expect(dto.dueAt, DateTime.utc(2026, 8, 30));
      expect(dto.collectedBank?.amountMinor, 600000);
    });

    test('S13 maps NOT_FOUND envelope to SalesContractException', () async {
      final rpc = _FakeRpcClient(
        error: RpcException(jsonEncode({'code': 'NOT_FOUND', 'message': 'Order not found.'})),
      );
      final gateway = SupabaseSalesOrderReadGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.getSalesOrder(_orderQuery()),
        throwsA(isA<SalesContractException>().having((e) => e.code, 'code', 'NOT_FOUND')),
      );
    });

    test('S13 translates malformed order envelope to DEPENDENCY_UNAVAILABLE', () async {
      final rpc = _FakeRpcClient(response: {'order': _orderResultJson()['order']});
      final gateway = SupabaseSalesOrderReadGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.getSalesOrder(_orderQuery()),
        throwsA(
          isA<SalesContractException>().having((e) => e.code, 'code', 'DEPENDENCY_UNAVAILABLE'),
        ),
      );
    });

    test('S13 translates malformed money and enum fields to DEPENDENCY_UNAVAILABLE', () async {
      final malformed = _orderResultJson();
      (malformed['order'] as Map<String, dynamic>)['total'] = {
        'amountMinor': 'not-an-integer',
        'currencyCode': '',
      };
      final rpc = _FakeRpcClient(response: malformed);
      final gateway = SupabaseSalesOrderReadGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.getSalesOrder(_orderQuery()),
        throwsA(
          isA<SalesContractException>().having((e) => e.code, 'code', 'DEPENDENCY_UNAVAILABLE'),
        ),
      );
    });
  });
}

GetSalesOrderQuery _orderQuery() =>
    GetSalesOrderQuery(tenantId: 'tenant-1', actorId: 'actor-1', salesOrderId: 'order-1');

Map<String, dynamic> _orderResultJson() => <String, dynamic>{
  'order': <String, dynamic>{
    'salesOrderId': 'order-1',
    'orderNumber': 'SO-000129',
    'version': 3,
    'lifecycleStatus': 'completed',
    'lockStatus': 'unlocked',
    'total': <String, dynamic>{'amountMinor': 4445238, 'currencyCode': 'VND'},
  },
  'committedAt': '2026-08-12T02:41:00.000Z',
  'store': <String, dynamic>{
    'storeId': 'store-1',
    'storeCode': 'HCM-01',
    'displayName': 'Store One',
  },
  'seller': <String, dynamic>{'actorId': 'actor-1', 'displayName': 'Minh Anh'},
  'customer': <String, dynamic>{
    'customerId': 'customer-1',
    'displayName': 'Nguyen Van An',
    'phoneNumber': '0903456789',
    'taxCode': null,
    'existingDebtMinor': 0,
  },
};

final class _FakeRpcClient implements IRpcClient {
  _FakeRpcClient({this.response = const <String, dynamic>{}, this.error});

  final Map<String, dynamic> response;
  final Object? error;
  String? lastProcedure;
  Map<String, dynamic>? lastParams;

  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async {
    lastProcedure = procedure;
    lastParams = params;
    if (error != null) throw error!;
    return response;
  }
}
