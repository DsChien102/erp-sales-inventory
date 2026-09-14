import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('SupabaseSalesOrderInquiryGateway', () {
    test('S15 list maps a cursor page of orders with snake_case paging params', () async {
      final rpc = _FakeRpcClient(
        response: {
          'items': [
            {
              'salesOrderId': 'order-1',
              'orderNumber': 'SO-0001',
              'sourceVersion': 1,
              'committedAt': '2026-08-07T00:00:00.000Z',
              'customer': {
                'customerId': 'customer-1',
                'displayName': 'Dai ly An Binh',
                'phoneNumber': '0903456789',
              },
              'store': {'storeId': 'store-1', 'storeCode': 'S01', 'displayName': 'Store 1'},
              'lifecycleStatus': 'completed',
              'lockStatus': 'unlocked',
              'settlementStatus': 'partiallyPaid',
              'returnStatus': 'none',
              'eInvoiceStatus': 'queued',
              'total': {'amountMinor': 1000000, 'currencyCode': 'VND'},
            },
          ],
          'hasMore': true,
          'nextCursor': 'cursor-2',
          'totalMatching': 1,
          'facets': {'all': 1, 'outstandingReceivable': 0, 'eInvoicePending': 1},
        },
      );
      final gateway = SupabaseSalesOrderInquiryGateway(rpcClient: rpc);

      final page = await gateway.listSalesOrders(
        ListSalesOrdersQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          pageSize: 10,
          filter: SalesOrderListFilterInput(
            completedFrom: DateTime.utc(2026, 8, 1),
            completedTo: DateTime.utc(2026, 8, 31, 23, 59, 59),
            storeId: 'store-1',
            settlementStatus: SalesSettlementStatus.partiallyPaid,
            hasReturnExchange: false,
            eInvoiceStatus: IntegrationDeliveryStatus.queued,
          ),
        ),
      );

      expect(rpc.lastProcedure, 'list_sales_orders');
      expect(rpc.lastParams?['page_size'], 10);
      expect(rpc.lastParams, containsPair('completed_from', '2026-08-01T00:00:00.000Z'));
      expect(rpc.lastParams, containsPair('completed_to', '2026-08-31T23:59:59.000Z'));
      expect(rpc.lastParams, containsPair('store_id', 'store-1'));
      expect(rpc.lastParams, containsPair('settlement_status', 'partiallyPaid'));
      expect(rpc.lastParams, containsPair('has_return_exchange', false));
      expect(rpc.lastParams, containsPair('e_invoice_status', 'queued'));
      expect(rpc.lastParams, containsPair('has_outstanding_receivable', isNull));
      expect(page.page.items.single.salesOrderId, 'order-1');
      expect(page.page.hasMore, isTrue);
      expect(page.page.nextCursor, 'cursor-2');
    });

    test('S15 search maps filter params and search text', () async {
      final rpc = _FakeRpcClient(response: {'items': [], 'hasMore': false, 'nextCursor': null});
      final gateway = SupabaseSalesOrderInquiryGateway(rpcClient: rpc);

      await gateway.searchSalesOrders(
        SearchSalesOrdersQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          searchText: 'SO-2026',
          filter: SalesOrderListFilterInput(
            completedFrom: DateTime.utc(2026, 8, 1),
            completedTo: DateTime.utc(2026, 8, 31, 23, 59, 59),
            storeId: 'store-1',
            settlementStatus: SalesSettlementStatus.partiallyPaid,
            hasReturnExchange: false,
            eInvoiceStatus: IntegrationDeliveryStatus.queued,
          ),
        ),
      );

      expect(rpc.lastProcedure, 'search_sales_orders');
      expect(rpc.lastParams, containsPair('search_text', 'SO-2026'));
      expect(rpc.lastParams, containsPair('completed_from', '2026-08-01T00:00:00.000Z'));
      expect(rpc.lastParams, containsPair('completed_to', '2026-08-31T23:59:59.000Z'));
      expect(rpc.lastParams, containsPair('store_id', 'store-1'));
      expect(rpc.lastParams, containsPair('settlement_status', 'partiallyPaid'));
      expect(rpc.lastParams, containsPair('has_return_exchange', false));
      expect(rpc.lastParams, containsPair('e_invoice_status', 'queued'));
      expect(rpc.lastParams, containsPair('has_outstanding_receivable', isNull));
    });

    test('S16 detail maps order + store + lines', () async {
      final rpc = _FakeRpcClient(
        response: {
          'order': {
            'salesOrderId': 'order-1',
            'orderNumber': 'SO-0001',
            'version': 1,
            'lifecycleStatus': 'completed',
            'lockStatus': 'unlocked',
            'total': {'amountMinor': 1000000, 'currencyCode': 'VND'},
          },
          'committedAt': '2026-08-12T03:15:00.000Z',
          'store': {'storeId': 'store-1', 'storeCode': 'S01', 'displayName': 'Store 1'},
          'seller': {'actorId': 'actor-1', 'displayName': 'Minh Anh'},
          'customer': null,
          'orderNote': 'Giao giờ hành chính',
          'currentReceiptId': 'receipt-1',
          'lines': [
            {
              'lineId': 'line-1',
              'product': {'productId': 'product-1', 'sku': 'SKU1', 'displayName': 'Sản phẩm 1'},
              'unit': {'productUnitId': 'unit-1', 'unitCode': 'BOX', 'unitName': 'Hộp'},
              'quantityMicros': 1000000,
              'unitPrice': {'amountMinor': 1000000, 'currencyCode': 'VND'},
              'lineTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
            },
          ],
        },
      );
      final gateway = SupabaseSalesOrderInquiryGateway(rpcClient: rpc);

      final dto = await gateway.getSalesOrderDetail(
        GetSalesOrderDetailQuery(tenantId: 'tenant-1', actorId: 'actor-1', salesOrderId: 'order-1'),
      );

      expect(rpc.lastProcedure, 'get_sales_order_detail');
      expect(dto.committedAt, DateTime.parse('2026-08-12T03:15:00.000Z'));
      expect(dto.store.storeCode, 'S01');
      expect(dto.seller.displayName, 'Minh Anh');
      expect(dto.orderNote, 'Giao giờ hành chính');
      expect(dto.currentReceiptId, 'receipt-1');
      expect(dto.lines.single.product.sku, 'SKU1');
    });

    test('S17 payment transactions maps a cursor page', () async {
      final rpc = _FakeRpcClient(
        response: {
          'items': [
            {
              'transactionId': 'txn-1',
              'method': 'cash',
              'amount': {'amountMinor': 400000, 'currencyCode': 'VND'},
              'status': 'confirmed',
              'recordedAt': '2026-08-07T00:00:00.000Z',
              'transactionType': 'collection',
              'direction': 'inflow',
              'relatedTransactionId': null,
              'sourceContext': 'checkout',
              'actorId': 'actor-1',
              'reasonCode': null,
              'reason': null,
            },
          ],
          'hasMore': false,
        },
      );
      final gateway = SupabaseSalesOrderInquiryGateway(rpcClient: rpc);

      final dto = await gateway.getPaymentTransactions(
        GetSalesOrderPaymentTransactionsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(rpc.lastProcedure, 'get_sales_order_payment_transactions');
      expect(dto.page.items.single.method, SalesPaymentMethod.cash);
      expect(dto.page.items.single.transactionType, SalesPaymentTransactionType.collection);
      expect(dto.page.items.single.direction, SalesPaymentDirection.inflow);
      expect(dto.page.items.single.actorId, 'actor-1');
      expect(dto.page.items.single.sourceContext, 'checkout');
    });

    test('S18 timeline maps entries with actor', () async {
      final rpc = _FakeRpcClient(
        response: {
          'salesOrderId': 'order-1',
          'entries': [
            {
              'eventId': 'evt-1',
              'eventType': 'sales.order.finalized',
              'occurredAt': '2026-08-07T00:00:00.000Z',
              'sourceVersion': 1,
              'actor': {'actorId': 'actor-1', 'displayName': 'Nhân viên'},
            },
          ],
        },
      );
      final gateway = SupabaseSalesOrderInquiryGateway(rpcClient: rpc);

      final dto = await gateway.getTimeline(
        GetSalesOrderTimelineQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(rpc.lastProcedure, 'get_sales_order_timeline');
      expect(dto.entries.single.actor?.displayName, 'Nhân viên');
    });

    test('S18 timeline leaves actor null when the fact has no actor evidence', () async {
      final rpc = _FakeRpcClient(
        response: {
          'salesOrderId': 'order-1',
          'entries': [
            {
              'eventId': 'evt-1',
              'eventType': 'sales_order_finalized.v1',
              'occurredAt': '2026-08-07T00:00:00.000Z',
              'sourceVersion': 1,
              'actor': null,
            },
          ],
        },
      );
      final gateway = SupabaseSalesOrderInquiryGateway(rpcClient: rpc);

      final dto = await gateway.getTimeline(
        GetSalesOrderTimelineQuery(
          tenantId: 'tenant-1',
          actorId: 'reader-2',
          salesOrderId: 'order-1',
        ),
      );

      expect(dto.entries.single.actor, isNull);
    });

    test('maps NOT_FOUND envelope to SalesContractException', () async {
      final rpc = _FakeRpcClient(
        error: RpcException(jsonEncode({'code': 'NOT_FOUND', 'message': 'Order not found.'})),
      );
      final gateway = SupabaseSalesOrderInquiryGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.getSalesOrderDetail(
          GetSalesOrderDetailQuery(tenantId: 'tenant-1', actorId: 'actor-1', salesOrderId: 'x'),
        ),
        throwsA(isA<SalesContractException>().having((e) => e.code, 'code', 'NOT_FOUND')),
      );
    });

    test('maps malformed result to DEPENDENCY_UNAVAILABLE', () async {
      final rpc = _FakeRpcClient(response: {'status': 'not-a-status'});
      final gateway = SupabaseSalesOrderInquiryGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.getSettlement(
          GetSalesOrderSettlementQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(
          isA<SalesContractException>().having((e) => e.code, 'code', 'DEPENDENCY_UNAVAILABLE'),
        ),
      );
    });
  });
}

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
