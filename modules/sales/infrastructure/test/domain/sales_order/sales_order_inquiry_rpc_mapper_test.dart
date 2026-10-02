import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';

void main() {
  group('SalesOrderInquiryRpcMapper list/search params', () {
    test('listParams maps full filter set including null optionals', () {
      final params = SalesOrderInquiryRpcMapper.listParams(
        ListSalesOrdersQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          pageSize: 25,
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

      expect(params['tenant_id'], 'tenant-1');
      expect(params['actor_id'], 'actor-1');
      expect(params, containsPair('completed_from', '2026-08-01T00:00:00.000Z'));
      expect(params, containsPair('completed_to', '2026-08-31T23:59:59.000Z'));
      expect(params, containsPair('store_id', 'store-1'));
      expect(params, containsPair('settlement_status', 'partiallyPaid'));
      expect(params, containsPair('has_return_exchange', false));
      expect(params, containsPair('e_invoice_status', 'queued'));
      expect(params, containsPair('seller_id', isNull));
      expect(params, containsPair('customer_id', isNull));
      expect(params, containsPair('has_outstanding_receivable', isNull));
    });

    test('searchParams maps full filter set including null optionals', () {
      final params = SalesOrderInquiryRpcMapper.searchParams(
        SearchSalesOrdersQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          searchText: 'SO',
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

      expect(params['actor_id'], 'actor-1');
      expect(params, containsPair('completed_from', '2026-08-01T00:00:00.000Z'));
      expect(params, containsPair('completed_to', '2026-08-31T23:59:59.000Z'));
      expect(params, containsPair('store_id', 'store-1'));
      expect(params, containsPair('settlement_status', 'partiallyPaid'));
      expect(params, containsPair('has_return_exchange', false));
      expect(params, containsPair('e_invoice_status', 'queued'));
      expect(params, containsPair('seller_id', isNull));
      expect(params, containsPair('customer_id', isNull));
      expect(params, containsPair('has_outstanding_receivable', isNull));
    });
  });

  group('SalesOrderInquiryRpcMapper pagedListFromJson', () {
    Map<String, dynamic> validPayload() {
      return <String, dynamic>{
        'items': [
          {
            'salesOrderId': '11111111-1111-1111-1111-111111111111',
            'orderNumber': 'SO-2026-00125',
            'sourceVersion': 7,
            'committedAt': '2026-08-12T03:15:00.000Z',
            'customer': {
              'customerId': 'customer-1',
              'displayName': 'Dai ly An Binh',
              'phoneNumber': '0903456789',
            },
            'store': {
              'storeId': 'store-1',
              'storeCode': 'HCM-01',
              'displayName': 'Chi nhanh Quan 1',
            },
            'total': {'amountMinor': 1250000, 'currencyCode': 'VND'},
            'lifecycleStatus': 'completed',
            'lockStatus': 'unlocked',
            'settlementStatus': 'partiallyPaid',
            'returnStatus': 'none',
            'eInvoiceStatus': 'queued',
          },
        ],
        'hasMore': true,
        'nextCursor': 'cursor-2',
        'totalMatching': 10,
        'facets': {
          'all': 10,
          'outstandingReceivable': 4,
          'eInvoicePending': 3,
        },
      };
    }

    test('parses authoritative list envelope fields', () {
      final dto = SalesOrderInquiryRpcMapper.pagedListFromJson(validPayload());
      final item = dto.page.items.single;

      expect(item.sourceVersion, 7);
      expect(item.committedAt, DateTime.parse('2026-08-12T03:15:00.000Z'));
      expect(item.customer?.displayName, 'Dai ly An Binh');
      expect(item.store.storeCode, 'HCM-01');
      expect(item.settlementStatus, SalesSettlementStatus.partiallyPaid);
      expect(item.returnStatus, SalesOrderReturnProjectionStatus.none);
      expect(item.eInvoiceStatus, IntegrationDeliveryStatus.queued);
      expect(dto.totalMatching, 10);
      expect(dto.facets?.all, 10);
      expect(dto.facets?.outstandingReceivable, 4);
      expect(dto.facets?.eInvoicePending, 3);
    });

    test('throws FormatException when required item field is missing', () {
      final payload = validPayload();
      final firstItem = (payload['items'] as List).first as Map<String, dynamic>;
      firstItem.remove('sourceVersion');

      expect(
        () => SalesOrderInquiryRpcMapper.pagedListFromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SalesOrderInquiryRpcMapper detailFromJson', () {
    Map<String, dynamic> validDetailPayload() {
      return <String, dynamic>{
        'order': {
          'salesOrderId': '11111111-1111-1111-1111-111111111111',
          'orderNumber': 'SO-2026-00125',
          'version': 7,
          'lifecycleStatus': 'completed',
          'lockStatus': 'unlocked',
          'total': {'amountMinor': 1250000, 'currencyCode': 'VND'},
        },
        'committedAt': '2026-08-12T03:15:00.000Z',
        'store': {
          'storeId': 'store-1',
          'storeCode': 'HCM-01',
          'displayName': 'Chi nhanh Quan 1',
        },
        'seller': {'actorId': 'actor-1', 'displayName': 'Minh Anh'},
        'customer': {
          'customerId': 'customer-1',
          'displayName': 'Dai ly An Binh',
          'phoneNumber': '0903456789',
        },
        'orderNote': 'Giao gio hanh chinh',
        'currentReceiptId': 'receipt-1',
        'lines': [
          {
            'lineId': 'line-1',
            'product': {
              'productId': 'product-1',
              'sku': 'SKU-1',
              'displayName': 'Amoxicillin 500mg',
            },
            'unit': {
              'productUnitId': 'unit-1',
              'unitCode': 'BOX',
              'unitName': 'Hop',
            },
            'quantityMicros': 1000000,
            'unitPrice': {'amountMinor': 1250000, 'currencyCode': 'VND'},
            'lineTotal': {'amountMinor': 1250000, 'currencyCode': 'VND'},
          },
        ],
      };
    }

    test('parses committedAt, seller, note, receipt and line snapshots', () {
      final dto = SalesOrderInquiryRpcMapper.detailFromJson(validDetailPayload());

      expect(dto.order.salesOrderId, '11111111-1111-1111-1111-111111111111');
      expect(dto.order.version, 7);
      expect(dto.committedAt, DateTime.parse('2026-08-12T03:15:00.000Z'));
      expect(dto.store.storeCode, 'HCM-01');
      expect(dto.seller.actorId, 'actor-1');
      expect(dto.seller.displayName, 'Minh Anh');
      expect(dto.customer?.displayName, 'Dai ly An Binh');
      expect(dto.orderNote, 'Giao gio hanh chinh');
      expect(dto.currentReceiptId, 'receipt-1');
      expect(dto.lines.single.product.displayName, 'Amoxicillin 500mg');
      expect(dto.lines.single.unit.unitCode, 'BOX');
    });

    test('maps line discount and current-line original unit price', () {
      final payload = validDetailPayload();
      ((payload['lines'] as List).single as Map<String, dynamic>)['discountTotal'] = {
        'amountMinor': 20000,
        'currencyCode': 'VND',
      };
      payload['currentLines'] = <Object?>[
        <String, dynamic>{
          'product': <String, dynamic>{'productId': 'p-a', 'sku': null, 'displayName': 'A'},
          'unit': <String, dynamic>{'productUnitId': 'u-a', 'unitCode': null, 'unitName': 'lọ'},
          'heldQuantity': <String, dynamic>{'quantityMicros': 2000000},
          'unitPrice': <String, dynamic>{'amountMinor': 90000, 'currencyCode': 'VND'},
          'originalUnitPrice': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
          'source': 'original',
        },
      ];

      final dto = SalesOrderInquiryRpcMapper.detailFromJson(payload);

      expect(dto.lines.single.discountTotal!.amountMinor, 20000);
      expect(dto.currentLines.single.originalUnitPrice!.amountMinor, 100000);
    });

    test('omits discount and original unit price when the keys are absent', () {
      final payload = validDetailPayload()
        ..['currentLines'] = <Object?>[
          <String, dynamic>{
            'product': <String, dynamic>{'productId': 'p-a', 'sku': null, 'displayName': 'A'},
            'unit': <String, dynamic>{'productUnitId': 'u-a', 'unitCode': null, 'unitName': 'lọ'},
            'heldQuantity': <String, dynamic>{'quantityMicros': 1000000},
            'unitPrice': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
            'source': 'original',
          },
        ];

      final dto = SalesOrderInquiryRpcMapper.detailFromJson(payload);

      expect(dto.lines.single.discountTotal, isNull);
      expect(dto.currentLines.single.originalUnitPrice, isNull);
    });

    test('allows null customer, orderNote and currentReceiptId', () {
      final payload = validDetailPayload()
        ..['customer'] = null
        ..['orderNote'] = null
        ..['currentReceiptId'] = null;

      final dto = SalesOrderInquiryRpcMapper.detailFromJson(payload);

      expect(dto.customer, isNull);
      expect(dto.orderNote, isNull);
      expect(dto.currentReceiptId, isNull);
    });

    test('throws FormatException when committedAt is missing', () {
      final payload = validDetailPayload()..remove('committedAt');

      expect(
        () => SalesOrderInquiryRpcMapper.detailFromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when seller snapshot is missing', () {
      final payload = validDetailPayload()..remove('seller');

      expect(
        () => SalesOrderInquiryRpcMapper.detailFromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when store snapshot is missing', () {
      final payload = validDetailPayload()..remove('store');

      expect(
        () => SalesOrderInquiryRpcMapper.detailFromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when required line snapshot is missing', () {
      final payload = validDetailPayload();
      final firstLine = (payload['lines'] as List).first as Map<String, dynamic>;
      firstLine.remove('product');

      expect(
        () => SalesOrderInquiryRpcMapper.detailFromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('decodes derived current holdings with exchange source', () {
      final payload = validDetailPayload()
        ..['currentLines'] = <Object?>[
          <String, dynamic>{
            'product': <String, dynamic>{'productId': 'p-b', 'sku': null, 'displayName': 'B'},
            'unit': <String, dynamic>{'productUnitId': 'u-b', 'unitCode': null, 'unitName': 'lọ'},
            'heldQuantity': <String, dynamic>{'quantityMicros': 1000000},
            'unitPrice': <String, dynamic>{'amountMinor': 1100000, 'currencyCode': 'VND'},
            'source': 'exchange',
          },
        ];

      final dto = SalesOrderInquiryRpcMapper.detailFromJson(payload);

      expect(dto.currentLines, hasLength(1));
      expect(dto.currentLines.single.source, SalesOrderLineSource.exchange);
      expect(dto.currentLines.single.heldQuantity.quantityMicros, 1000000);
      expect(dto.currentLines.single.product.displayName, 'B');
      expect(dto.currentLines.single.unit.unitName, 'lọ');
      expect(dto.currentLines.single.unitPrice.amountMinor, 1100000);
    });

    test('detail without currentLines decodes to empty (backward compatible)', () {
      final dto = SalesOrderInquiryRpcMapper.detailFromJson(validDetailPayload());

      expect(dto.currentLines, isEmpty);
    });
  });

  group('SalesOrderInquiryRpcMapper S17-S18 settlement/timeline/return', () {
    test('transactionsParams preserves cursor and page_size', () {
      final params = SalesOrderInquiryRpcMapper.transactionsParams(
        GetSalesOrderPaymentTransactionsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          expectedSourceVersion: 7,
          cursor: '2026-08-07T00:00:00.000Z|txn-1',
          pageSize: 10,
        ),
      );

      expect(params, containsPair('cursor', '2026-08-07T00:00:00.000Z|txn-1'));
      expect(params, containsPair('page_size', 10));
      expect(params, containsPair('expected_source_version', 7));
    });

    test('settlementFromJson maps independent paid/refunded/outstanding totals', () {
      final dto = SalesOrderInquiryRpcMapper.settlementFromJson({
        'settlementId': 'settlement-1',
        'salesOrderId': 'order-1',
        'version': 3,
        'status': 'partiallyPaid',
        'orderTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
        'paidTotal': {'amountMinor': 400000, 'currencyCode': 'VND'},
        'refundedTotal': {'amountMinor': 50000, 'currencyCode': 'VND'},
        'outstanding': {'amountMinor': 650000, 'currencyCode': 'VND'},
        'dueAt': '2026-08-30T00:00:00.000Z',
      });

      expect(dto.paidTotal.amountMinor, 400000);
      expect(dto.refundedTotal.amountMinor, 50000);
      expect(dto.outstanding.amountMinor, 650000);
      expect(dto.dueAt, DateTime.parse('2026-08-30T00:00:00.000Z'));
    });

    test('settlementFromJson fails closed when required money totals are missing', () {
      final base = <String, dynamic>{
        'settlementId': 'settlement-1',
        'salesOrderId': 'order-1',
        'version': 3,
        'status': 'partiallyPaid',
        'orderTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
        'paidTotal': {'amountMinor': 400000, 'currencyCode': 'VND'},
        'refundedTotal': {'amountMinor': 50000, 'currencyCode': 'VND'},
        'outstanding': {'amountMinor': 650000, 'currencyCode': 'VND'},
      };

      for (final missing in ['orderTotal', 'paidTotal', 'refundedTotal', 'outstanding']) {
        final json = Map<String, dynamic>.from(base)..remove(missing);
        expect(
          () => SalesOrderInquiryRpcMapper.settlementFromJson(json),
          throwsA(isA<FormatException>()),
          reason: 'missing $missing must fail closed',
        );
      }

      expect(
        () => SalesOrderInquiryRpcMapper.settlementFromJson(
          Map<String, dynamic>.from(base)..remove('settlementId'),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('timelineFromJson maps optional description and amount', () {
      final dto = SalesOrderInquiryRpcMapper.timelineFromJson({
        'salesOrderId': 'order-1',
        'entries': [
          {
            'eventId': 'evt-1',
            'eventType': 'order_note_updated',
            'occurredAt': '2026-08-07T00:00:00.000Z',
            'sourceVersion': 2,
            'actor': {'actorId': 'actor-1', 'displayName': 'Minh Anh'},
            'description': 'Giao sáng → Giao chiều',
            'amount': null,
          },
        ],
      });

      expect(dto.entries.single.description, 'Giao sáng → Giao chiều');
      expect(dto.entries.single.amount, isNull);
    });

    test('returnSummaryFromJson maps typed return exchange summaries', () {
      final dto = SalesOrderInquiryRpcMapper.returnSummaryFromJson({
        'salesOrderId': 'order-1',
        'returns': [
          {
            'returnExchangeId': 're-1',
            'referenceNumber': 're-1',
            'status': 'completed',
            'completedAt': '2026-08-10T04:00:00.000Z',
            'settlementDifference': {'amountMinor': 150000, 'currencyCode': 'VND'},
          },
        ],
      });

      expect(dto.returns.single.referenceNumber, 're-1');
      expect(dto.returns.single.settlementDifference.amountMinor, 150000);
      expect(dto.returns.single.completedAt, DateTime.parse('2026-08-10T04:00:00.000Z'));
    });

    test('returnSummaryFromJson fails closed when required row fields are missing', () {
      expect(
        () => SalesOrderInquiryRpcMapper.returnSummaryFromJson({
          'returns': const [],
        }),
        throwsA(isA<FormatException>()),
      );

      final row = <String, dynamic>{
        'returnExchangeId': 're-1',
        'referenceNumber': 're-1',
        'status': 'completed',
        'completedAt': '2026-08-10T04:00:00.000Z',
        'settlementDifference': {'amountMinor': 150000, 'currencyCode': 'VND'},
      };
      for (final missing in [
        'returnExchangeId',
        'referenceNumber',
        'status',
        'settlementDifference',
      ]) {
        final json = <String, dynamic>{
          'salesOrderId': 'order-1',
          'returns': [Map<String, dynamic>.from(row)..remove(missing)],
        };
        expect(
          () => SalesOrderInquiryRpcMapper.returnSummaryFromJson(json),
          throwsA(isA<FormatException>()),
          reason: 'missing $missing must fail closed',
        );
      }
    });
  });
}
