import 'dart:collection';

import '../return_exchange_order/queries/get_sales_order_return_summary/get_sales_order_return_summary_query.dart';
import '../sales_order/ports/i_sales_order_inquiry_gateway.dart';
import '../sales_order/queries/get_sales_order_detail/get_sales_order_detail_query.dart';
import '../sales_order/queries/get_sales_order_timeline/get_sales_order_timeline_query.dart';
import '../sales_order/queries/list_sales_orders/list_sales_orders_query.dart';
import '../sales_order/queries/search_sales_orders/search_sales_orders_query.dart';
import '../sales_order_settlement/queries/get_sales_order_payment_transactions/get_sales_order_payment_transactions_query.dart';
import '../sales_order_settlement/queries/get_sales_order_settlement/get_sales_order_settlement_query.dart';
import '../shared/actor_snapshot_dto.dart';
import '../shared/money_dto.dart';
import '../shared/opaque_cursor_page_dto.dart';
import '../shared/paged_sales_order_list_dto.dart';
import '../shared/sales_contract_enums.dart';
import '../shared/sales_order_detail_dto.dart';
import '../shared/sales_order_dto.dart';
import '../shared/sales_order_list_item_dto.dart';
import '../shared/sales_order_return_summary_dto.dart';
import '../shared/sales_order_settlement_dto.dart';
import '../shared/sales_order_timeline_dto.dart';
import '../shared/sales_payment_transactions_dto.dart';
import '../shared/store_snapshot_dto.dart';

/// Dequeues the next value from [queue]. When only one item remains it is
/// retained and returned on every subsequent call (sticky last value).
T _dequeue<T>(Queue<T> queue) {
  if (queue.length > 1) return queue.removeFirst();
  return queue.first;
}

final class FakeSalesOrderInquiryGateway implements ISalesOrderInquiryGateway {
  FakeSalesOrderInquiryGateway({
    PagedSalesOrderListDto? list,
    PagedSalesOrderListDto? search,
    SalesOrderDetailDto? detail,
    SalesOrderSettlementDto? settlement,
    SalesPaymentTransactionsDto? transactions,
    SalesOrderTimelineDto? timeline,
    SalesOrderReturnSummaryDto? returnSummary,
    Object? error,
    Object? listError,
    Object? searchError,
  }) : _detail = detail,
       _settlement = settlement,
       _transactions = transactions,
       _timeline = timeline,
       _returnSummary = returnSummary {
    if (list != null) _listQueue.add(list);
    if (search != null) _searchQueue.add(search);
    if (error != null) _errorQueue.add(error);
    if (listError != null) _listErrorQueue.add(listError);
    if (searchError != null) _searchErrorQueue.add(searchError);
  }

  final Queue<PagedSalesOrderListDto> _listQueue = Queue();
  final Queue<PagedSalesOrderListDto> _searchQueue = Queue();
  final Queue<Object> _errorQueue = Queue();
  final Queue<Object> _listErrorQueue = Queue();
  final Queue<Object> _searchErrorQueue = Queue();
  final SalesOrderDetailDto? _detail;
  final SalesOrderSettlementDto? _settlement;
  final SalesPaymentTransactionsDto? _transactions;
  final SalesOrderTimelineDto? _timeline;
  final SalesOrderReturnSummaryDto? _returnSummary;

  /// Enqueue additional list responses for successive calls.
  void enqueueList(PagedSalesOrderListDto dto) => _listQueue.add(dto);

  /// Enqueue additional search responses for successive calls.
  void enqueueSearch(PagedSalesOrderListDto dto) => _searchQueue.add(dto);

  /// Enqueue an error to throw on the next list call.
  void enqueueListError(Object err) => _listErrorQueue.add(err);

  /// Enqueue an error to throw on the next search call.
  void enqueueSearchError(Object err) => _searchErrorQueue.add(err);

  /// Enqueue a general error (applies to any call type).
  void enqueueError(Object err) => _errorQueue.add(err);

  int listCalls = 0;
  int searchCalls = 0;
  int detailCalls = 0;
  int settlementCalls = 0;
  int transactionsCalls = 0;
  int timelineCalls = 0;
  int returnSummaryCalls = 0;
  ListSalesOrdersQuery? lastListQuery;
  SearchSalesOrdersQuery? lastSearchQuery;
  GetSalesOrderReturnSummaryQuery? lastReturnSummaryQuery;

  static PagedSalesOrderListDto _emptyPage() {
    return PagedSalesOrderListDto(
      page: OpaqueCursorPageDto<SalesOrderListItemDto>(items: const [], hasMore: false),
    );
  }

  @override
  Future<PagedSalesOrderListDto> listSalesOrders(ListSalesOrdersQuery query) async {
    listCalls += 1;
    lastListQuery = query;
    if (_listErrorQueue.isNotEmpty) throw _dequeue(_listErrorQueue);
    if (_errorQueue.isNotEmpty) throw _dequeue(_errorQueue);
    if (_listQueue.isNotEmpty) return _dequeue(_listQueue);
    return _emptyPage();
  }

  @override
  Future<PagedSalesOrderListDto> searchSalesOrders(SearchSalesOrdersQuery query) async {
    searchCalls += 1;
    lastSearchQuery = query;
    if (_searchErrorQueue.isNotEmpty) throw _dequeue(_searchErrorQueue);
    if (_errorQueue.isNotEmpty) throw _dequeue(_errorQueue);
    if (_searchQueue.isNotEmpty) return _dequeue(_searchQueue);
    return _emptyPage();
  }

  @override
  Future<SalesOrderDetailDto> getSalesOrderDetail(GetSalesOrderDetailQuery query) async {
    detailCalls += 1;
    if (_errorQueue.isNotEmpty) throw _dequeue(_errorQueue);
    return _detail ??
        SalesOrderDetailDto(
          order: SalesOrderDto(
            salesOrderId: query.salesOrderId,
            orderNumber: 'SO-0001',
            version: 1,
            lifecycleStatus: SalesOrderLifecycleStatus.completed,
            lockStatus: SalesOrderLockStatus.unlocked,
            total: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          ),
          committedAt: DateTime.utc(2026, 8, 12, 3, 15),
          store: const StoreSnapshotDto(
            storeId: 'store-1',
            storeCode: 'S01',
            displayName: 'Store 1',
          ),
          seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
          lines: const [],
        );
  }

  @override
  Future<SalesOrderSettlementDto> getSettlement(GetSalesOrderSettlementQuery query) async {
    settlementCalls += 1;
    if (_errorQueue.isNotEmpty) throw _dequeue(_errorQueue);
    return _settlement ??
        SalesOrderSettlementDto(
          settlementId: 'settlement-1',
          salesOrderId: query.salesOrderId,
          version: 1,
          status: SalesSettlementStatus.paid,
          orderTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          paidTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          refundedTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          outstanding: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        );
  }

  @override
  Future<SalesPaymentTransactionsDto> getPaymentTransactions(
    GetSalesOrderPaymentTransactionsQuery query,
  ) async {
    transactionsCalls += 1;
    if (_errorQueue.isNotEmpty) throw _dequeue(_errorQueue);
    return _transactions ??
        SalesPaymentTransactionsDto(
          page: OpaqueCursorPageDto(items: const [], hasMore: false),
        );
  }

  @override
  Future<SalesOrderTimelineDto> getTimeline(GetSalesOrderTimelineQuery query) async {
    timelineCalls += 1;
    if (_errorQueue.isNotEmpty) throw _dequeue(_errorQueue);
    return _timeline ?? SalesOrderTimelineDto(salesOrderId: query.salesOrderId, entries: const []);
  }

  @override
  Future<SalesOrderReturnSummaryDto> getReturnSummary(
    GetSalesOrderReturnSummaryQuery query,
  ) async {
    returnSummaryCalls += 1;
    lastReturnSummaryQuery = query;
    if (_errorQueue.isNotEmpty) throw _dequeue(_errorQueue);
    return _returnSummary ??
        SalesOrderReturnSummaryDto(salesOrderId: query.salesOrderId, returns: const []);
  }
}
