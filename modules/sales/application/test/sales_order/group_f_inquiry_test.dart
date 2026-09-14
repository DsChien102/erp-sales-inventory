import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

final class _AllowAllPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {}
}

final class _DenyPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {
    throw const SalesContractException('PERMISSION_DENIED', message: 'Denied in test.');
  }
}

SalesOrderListItemDto _sampleItem() => SalesOrderListItemDto(
  salesOrderId: '11111111-1111-1111-1111-111111111111',
  orderNumber: 'SO-2026-00125',
  sourceVersion: 7,
  committedAt: DateTime.utc(2026, 8, 12, 3, 15),
  customer: const CustomerSnapshotDto(
    customerId: 'customer-1',
    displayName: 'Đại lý An Bình',
    phoneNumber: '0903456789',
  ),
  store: const StoreSnapshotDto(
    storeId: 'store-1',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
  ),
  total: const MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
  lifecycleStatus: SalesOrderLifecycleStatus.completed,
  lockStatus: SalesOrderLockStatus.unlocked,
  settlementStatus: SalesSettlementStatus.partiallyPaid,
  returnStatus: SalesOrderReturnProjectionStatus.none,
  eInvoiceStatus: IntegrationDeliveryStatus.queued,
);

SalesOrderListFilterInput _sampleFilter() => SalesOrderListFilterInput(
  completedFrom: DateTime.utc(2026, 8, 1),
  completedTo: DateTime.utc(2026, 8, 31, 23, 59, 59),
  storeId: 'store-1',
  lifecycleStatus: SalesOrderLifecycleStatus.completed,
  settlementStatus: SalesSettlementStatus.partiallyPaid,
  hasReturnExchange: false,
  eInvoiceStatus: IntegrationDeliveryStatus.queued,
);

void main() {
  group('TH-05 Group F-read S15 list/search', () {
    test('S15 list returns typed SalesOrderListItemDto items', () async {
      final item = _sampleItem();
      final gateway = FakeSalesOrderInquiryGateway(
        list: PagedSalesOrderListDto(
          page: OpaqueCursorPageDto<SalesOrderListItemDto>(
            items: [item],
            hasMore: true,
            nextCursor: 'cursor-2',
          ),
          totalMatching: 42,
          facets: const SalesOrderListFacetsDto(
            all: 42,
            outstandingReceivable: 5,
            eInvoicePending: 3,
          ),
        ),
      );
      final handler = ListSalesOrdersQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        inquiryGateway: gateway,
      );

      final result = await handler.handle(
        ListSalesOrdersQuery(tenantId: 'tenant-1', actorId: 'actor-1'),
      );

      expect(result.page.items.single.salesOrderId, '11111111-1111-1111-1111-111111111111');
      expect(result.page.items.single.orderNumber, 'SO-2026-00125');
      expect(result.page.items.single.sourceVersion, 7);
      expect(result.page.items.single.committedAt, DateTime.utc(2026, 8, 12, 3, 15));
      expect(result.page.items.single.customer?.displayName, 'Đại lý An Bình');
      expect(result.page.items.single.store.storeCode, 'HCM-01');
      expect(result.page.items.single.total.amountMinor, 1250000);
      expect(result.page.items.single.lifecycleStatus, SalesOrderLifecycleStatus.completed);
      expect(result.page.items.single.settlementStatus, SalesSettlementStatus.partiallyPaid);
      expect(result.page.items.single.returnStatus, SalesOrderReturnProjectionStatus.none);
      expect(result.page.items.single.eInvoiceStatus, IntegrationDeliveryStatus.queued);
      expect(result.page.hasMore, isTrue);
      expect(result.page.nextCursor, 'cursor-2');
      expect(result.totalMatching, 42);
      expect(result.facets?.all, 42);
      expect(result.facets?.outstandingReceivable, 5);
      expect(result.facets?.eInvoicePending, 3);
      expect(gateway.listCalls, 1);
    });

    test('S15 outstanding filter null true and false are distinct', () {
      for (final value in <bool?>[null, true, false]) {
        final filter = SalesOrderListFilterInput(hasOutstandingReceivable: value);
        final list = ListSalesOrdersQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          filter: filter,
        );
        final search = SearchSalesOrdersQuery(
          tenantId: 'tenant-1',
          actorId: 'reader-2',
          searchText: 'SO-OLD',
          filter: filter,
        );

        expect(list.filter?.hasOutstandingReceivable, value);
        expect(search.filter?.hasOutstandingReceivable, value);
        expect(search.actorId, isNot('actor-1'));
      }
    });

    test('S18 timeline keeps a missing actor null instead of the reader', () {
      final entry = SalesOrderTimelineEntryDto(
        eventId: 'evt-1',
        eventType: 'sales_order_finalized.v1',
        occurredAt: DateTime.utc(2026, 9, 9),
        sourceVersion: 1,
      );

      expect(entry.actor, isNull);
    });

    test('S15 list withExecutionContext preserves filter', () {
      final filter = _sampleFilter();
      final query = ListSalesOrdersQuery(
        cursor: 'c1',
        pageSize: 10,
        filter: filter,
      );
      final bound = query.withExecutionContext(tenantId: 'tenant-1', actorId: 'actor-1');

      expect(bound.id, query.id);
      expect(bound.tenantId, 'tenant-1');
      expect(bound.cursor, 'c1');
      expect(bound.pageSize, 10);
      expect(bound.filter, same(filter));
    });

    test('S15 search forwards filter and returns a page', () async {
      final filter = _sampleFilter();
      final gateway = FakeSalesOrderInquiryGateway();
      final handler = SearchSalesOrdersQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        inquiryGateway: gateway,
      );

      final page = await handler.handle(
        SearchSalesOrdersQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          searchText: 'SO-0001',
          filter: filter,
        ),
      );

      expect(page.page.items, isEmpty);
      expect(gateway.searchCalls, 1);
      expect(gateway.lastSearchQuery?.filter, same(filter));
      expect(gateway.lastSearchQuery?.searchText, 'SO-0001');
    });

    test('S15 search withExecutionContext preserves filter', () {
      final filter = _sampleFilter();
      final query = SearchSalesOrdersQuery(
        searchText: 'abc',
        cursor: 'c2',
        pageSize: 15,
        filter: filter,
      );
      final bound = query.withExecutionContext(tenantId: 'tenant-1');

      expect(bound.id, query.id);
      expect(bound.searchText, 'abc');
      expect(bound.cursor, 'c2');
      expect(bound.pageSize, 15);
      expect(bound.filter, same(filter));
    });

    test('S15 list enforces sales.order.view before the gateway', () async {
      final gateway = FakeSalesOrderInquiryGateway();
      final handler = ListSalesOrdersQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        inquiryGateway: gateway,
      );

      await expectLater(
        () => handler.handle(ListSalesOrdersQuery(tenantId: 'tenant-1', actorId: 'actor-1')),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.listCalls, 0);
    });

    test('fake gateway captures lastListQuery', () async {
      final gateway = FakeSalesOrderInquiryGateway();
      final handler = ListSalesOrdersQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        inquiryGateway: gateway,
      );
      final filter = _sampleFilter();
      final query = ListSalesOrdersQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        filter: filter,
      );

      await handler.handle(query);

      expect(gateway.lastListQuery, same(query));
    });
  });

  group('TH-05 Group F-read S16 detail / S18 timeline + return summary', () {
    test('S16 detail returns committed identity, seller, note and receipt', () async {
      const order = SalesOrderDto(
        salesOrderId: 'order-1',
        orderNumber: 'SO-2026-00125',
        version: 7,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
      );
      const store = StoreSnapshotDto(
        storeId: 'store-1',
        storeCode: 'HCM-01',
        displayName: 'Chi nhánh Quận 1',
      );
      const customer = CustomerSnapshotDto(
        customerId: 'customer-1',
        displayName: 'Đại lý An Bình',
        phoneNumber: '0903456789',
      );
      const lines = [
        SalesOrderLineDto(
          lineId: 'line-1',
          product: ProductSnapshotDto(
            productId: 'product-1',
            sku: 'SKU-1',
            displayName: 'Amoxicillin 500mg',
          ),
          unit: ProductUnitSnapshotDto(
            productUnitId: 'unit-1',
            unitCode: 'BOX',
            unitName: 'Hộp',
          ),
          quantity: QuantityDto(quantityMicros: 1000000),
          unitPrice: MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
          lineTotal: MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
        ),
      ];
      final detail = SalesOrderDetailDto(
        order: order,
        committedAt: DateTime.utc(2026, 8, 12, 3, 15),
        store: store,
        seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
        customer: customer,
        lines: lines,
        orderNote: 'Giao giờ hành chính',
        currentReceiptId: 'receipt-1',
      );
      final gateway = FakeSalesOrderInquiryGateway(detail: detail);
      final handler = GetSalesOrderDetailQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        inquiryGateway: gateway,
      );

      final dto = await handler.handle(
        GetSalesOrderDetailQuery(tenantId: 'tenant-1', actorId: 'actor-1', salesOrderId: 'order-1'),
      );

      expect(dto.order.salesOrderId, 'order-1');
      expect(dto.order.version, 7);
      expect(dto.committedAt, DateTime.utc(2026, 8, 12, 3, 15));
      expect(dto.store.storeCode, 'HCM-01');
      expect(dto.seller.displayName, 'Minh Anh');
      expect(dto.customer?.displayName, 'Đại lý An Bình');
      expect(dto.lines.single.product.sku, 'SKU-1');
      expect(dto.orderNote, 'Giao giờ hành chính');
      expect(dto.currentReceiptId, 'receipt-1');
      expect(gateway.detailCalls, 1);
    });

    test('S18 timeline returns entries with optional description and amount', () async {
      final gateway = FakeSalesOrderInquiryGateway(
        timeline: SalesOrderTimelineDto(
          salesOrderId: 'order-1',
          entries: [
            SalesOrderTimelineEntryDto(
              eventId: 'evt-1',
              eventType: 'sales.order.finalized',
              occurredAt: DateTime.utc(2026, 8, 7),
              sourceVersion: 1,
              actor: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Nhân viên'),
              description: 'Hoàn tất đơn hàng',
              amount: const MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
            ),
          ],
        ),
      );
      final handler = GetSalesOrderTimelineQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        inquiryGateway: gateway,
      );

      final dto = await handler.handle(
        GetSalesOrderTimelineQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(dto.entries.single.eventType, 'sales.order.finalized');
      expect(dto.entries.single.description, 'Hoàn tất đơn hàng');
      expect(dto.entries.single.amount?.amountMinor, 1250000);
      expect(gateway.timelineCalls, 1);
    });

    test('S18 timeline enforces sales.order.history.view before the gateway', () async {
      final gateway = FakeSalesOrderInquiryGateway();
      final handler = GetSalesOrderTimelineQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        inquiryGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          GetSalesOrderTimelineQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.timelineCalls, 0);
    });

    test('S18 return summary returns typed return exchange summaries', () async {
      final gateway = FakeSalesOrderInquiryGateway(
        returnSummary: SalesOrderReturnSummaryDto(
          salesOrderId: 'order-1',
          returns: [
            ReturnExchangeSummaryDto(
              returnExchangeId: 're-1',
              referenceNumber: 're-1',
              status: ReturnExchangeStatus.completed,
              completedAt: DateTime.utc(2026, 8, 10, 4),
              settlementDifference: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
            ),
          ],
        ),
      );
      final handler = GetSalesOrderReturnSummaryQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        inquiryGateway: gateway,
      );

      final dto = await handler.handle(
        GetSalesOrderReturnSummaryQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(dto.salesOrderId, 'order-1');
      expect(dto.returns.single.returnExchangeId, 're-1');
      expect(dto.returns.single.referenceNumber, 're-1');
      expect(dto.returns.single.status, ReturnExchangeStatus.completed);
      expect(dto.returns.single.completedAt, DateTime.utc(2026, 8, 10, 4));
      expect(dto.returns.single.settlementDifference.amountMinor, 150000);
      expect(gateway.returnSummaryCalls, 1);
    });

    test(
      'S34 reuses Group F inquiry gateway for return summary without a new owner RPC',
      () async {
        final gateway = FakeSalesOrderInquiryGateway();
        final handler = GetSalesOrderReturnSummaryQueryHandler(
          permissionChecker: _AllowAllPermissionChecker(),
          inquiryGateway: gateway,
        );

        await handler.handle(
          GetSalesOrderReturnSummaryQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-34',
          ),
        );

        expect(gateway.returnSummaryCalls, 1);
        expect(gateway.lastReturnSummaryQuery?.salesOrderId, 'order-34');
        expect(handler, isA<GetSalesOrderReturnSummaryQueryHandler>());
      },
    );
  });
}
