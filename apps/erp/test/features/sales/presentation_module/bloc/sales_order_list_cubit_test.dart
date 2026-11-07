import 'dart:async';

import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart' as app;

import '../../support/fake_sales_order_repository.dart';
import '../../support/sales_contract_error.dart';

void main() {
  group('SalesOrderListCubit server state', () {
    test('loadInitial binds tenant actor store and cursor null', () async {
      final repo = _ScriptedOrderRepository();
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      final query = repo.listCalls.single;
      expect(repo.searchCalls, isEmpty);
      expect(query.filter?.storeId, 'store-1');
      expect(query.cursor, isNull);
    });

    test('searchByKeyword sends SearchSalesOrdersQuery and resets cursor', () async {
      final repo = _ScriptedOrderRepository();
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.searchByKeyword('SO-001');

      final query = repo.searchCalls.single;
      expect(repo.listCalls, isEmpty);
      expect(query.searchText, 'SO-001');
      expect(query.cursor, isNull);
      expect(query.filter?.storeId, 'store-1');
    });

    test('loadMore uses nextCursor and dedupes ids', () async {
      final repo = _ScriptedOrderRepository(
        responses: [
          _OkResp(_ok(items: [_dto('so-1')], hasMore: true, nextCursor: 'c2')),
          _OkResp(_ok(items: [_dto('so-1'), _dto('so-2')], hasMore: false)),
        ],
      );
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await cubit.loadMore();

      final second = repo.listCalls.last;
      expect(second.cursor, 'c2');
      final state = cubit.state as SalesOrderListLoaded;
      expect(state.items.map((e) => e.salesOrderId).toList(), ['so-1', 'so-2']);
      expect(state.hasMore, isFalse);
    });

    test('loadMore error keeps rows and sets loadMoreError', () async {
      final repo = _ScriptedOrderRepository(
        responses: [
          _OkResp(_ok(items: [_dto('so-1')], hasMore: true, nextCursor: 'c2')),
          _Err(salesContractError('TRANSPORT_ERROR', message: 'network down')),
        ],
      );
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await cubit.loadMore();

      final state = cubit.state as SalesOrderListLoaded;
      expect(state.items, hasLength(1));
      expect(state.loadMoreError, 'Không thể tải thêm đơn hàng. Vui lòng thử lại.');
      expect(state.isLoadingMore, isFalse);
    });

    test('stale response does not override newer generation', () async {
      final listCompleter = Completer<app.PagedSalesOrderListDto>();
      final searchCompleter = Completer<app.PagedSalesOrderListDto>();
      final repo = _ScriptedOrderRepository(
        listBuilder: (_) => listCompleter.future,
        searchBuilder: () => searchCompleter.future,
      );
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      final a = cubit.loadInitial();
      final b = cubit.searchByKeyword('new');

      searchCompleter.complete(_ok(items: [_dto('so-new')]));
      await b;
      listCompleter.complete(_ok(items: [_dto('so-old')]));
      await a;

      final state = cubit.state as SalesOrderListLoaded;
      expect(state.items.single.salesOrderId, 'so-new');
      expect(state.requestGeneration, 2);
    });

    test('permission denied maps to blocked state', () async {
      final repo = _ScriptedOrderRepository.failing(salesContractError('PERMISSION_DENIED'));
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      expect(
        cubit.state,
        isA<SalesOrderListBlocked>().having(
          (s) => s.message,
          'message',
          'Không có quyền xem đơn hàng',
        ),
      );
    });

    test('data scope denied maps to blocked state', () async {
      final repo = _ScriptedOrderRepository.failing(salesContractError('DATA_SCOPE_DENIED'));
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      expect(
        cubit.state,
        isA<SalesOrderListBlocked>().having(
          (s) => s.message,
          'message',
          'Không có quyền xem đơn hàng',
        ),
      );
    });

    test('projection pending maps to generic list error', () async {
      final repo = _ScriptedOrderRepository.failing(salesContractError('PROJECTION_PENDING'));
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      final state = cubit.state as SalesOrderListError;
      expect(state.message, 'Không thể tải danh sách đơn hàng.');
    });

    test('transport retryable error maps to generic list error', () async {
      final repo = _ScriptedOrderRepository.failing(salesContractError('TRANSPORT_RETRYABLE'));
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      final state = cubit.state as SalesOrderListError;
      expect(state.message, 'Không thể tải danh sách đơn hàng.');
    });

    test('load_error_shows_accented_message', () async {
      final repo = _ScriptedOrderRepository.failing(salesContractError('UNKNOWN_ERROR'));
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      final state = cubit.state as SalesOrderListError;
      expect(state.message, 'Không thể tải danh sách đơn hàng.');
    });

    test('load_more_error_never_shows_server_message', () async {
      final repo = _ScriptedOrderRepository(
        responses: [
          _OkResp(_ok(items: [_dto('so-1')], hasMore: true, nextCursor: 'c2')),
          _Err(salesContractError('UNKNOWN', message: 'raw server explosion')),
        ],
      );
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await cubit.loadMore();

      final state = cubit.state as SalesOrderListLoaded;
      expect(state.loadMoreError, 'Không thể tải thêm đơn hàng. Vui lòng thử lại.');
      expect(state.loadMoreError, isNot(contains('server')));
    });

    test('blocked_on_no_permission', () async {
      final repo = _ScriptedOrderRepository.failing(salesContractError('PERMISSION_DENIED'));
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      expect(
        cubit.state,
        isA<SalesOrderListBlocked>().having(
          (s) => s.message,
          'message',
          'Không có quyền xem đơn hàng',
        ),
      );
    });

    test('blocked_on_data_scope_denied', () async {
      final repo = _ScriptedOrderRepository.failing(salesContractError('DATA_SCOPE_DENIED'));
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      expect(
        cubit.state,
        isA<SalesOrderListBlocked>().having(
          (s) => s.message,
          'message',
          'Không có quyền xem đơn hàng',
        ),
      );
    });

    test('applyFilters dispatches a new server query, cursor null, carries storeId', () async {
      final repo = _ScriptedOrderRepository(
        responses: [
          _OkResp(_ok(items: [_dto('so-1')])),
          _OkResp(_ok(items: [_dto('so-2')])),
        ],
      );
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await cubit.applyFilters(lifecycleFilter: SalesOrderListLifecycleFilter.completed);

      expect(repo.listCalls, hasLength(2));
      expect(repo.searchCalls, isEmpty);
      final query = repo.listCalls.last;
      expect(query.cursor, isNull);
      expect(query.filter?.storeId, 'store-1');
      expect(query.filter?.lifecycleStatus, app.SalesOrderLifecycleStatus.completed);
    });

    test('applyFilters retains previous items and is not a first-load skeleton', () async {
      final second = Completer<app.PagedSalesOrderListDto>();
      final repo = _ScriptedOrderRepository(
        listBuilder: (call) => call == 1
            ? Future.value(_ok(items: [_dto('so-1')]))
            : second.future,
      );
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      final pending = cubit.applyFilters(
        lifecycleFilter: SalesOrderListLifecycleFilter.completed,
      );
      await Future<void>.delayed(Duration.zero);

      final loading = cubit.state as SalesOrderListLoading;
      expect(loading.items, hasLength(1));
      expect(loading.items.single.salesOrderId, 'so-1');
      expect(loading.isFirstLoad, isFalse);
      expect(loading.lifecycleFilter, SalesOrderListLifecycleFilter.completed);

      second.complete(_ok(items: [_dto('so-2')]));
      await pending;

      final loaded = cubit.state as SalesOrderListLoaded;
      expect(loaded.items.single.salesOrderId, 'so-2');
    });

    test('empty default scope is distinct from filtered no-result', () async {
      final repo = _ScriptedOrderRepository(
        responses: [_OkResp(_ok()), _OkResp(_ok())],
      );
      final cubit = _buildCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      final emptyDefault = cubit.state as SalesOrderListLoaded;
      expect(emptyDefault.items, isEmpty);
      expect(emptyDefault.isDefaultScopeEmpty, isTrue);
      expect(emptyDefault.activeFilterCount, 0);

      await cubit.applyFilters(lifecycleFilter: SalesOrderListLifecycleFilter.completed);
      final noResult = cubit.state as SalesOrderListLoaded;
      expect(noResult.items, isEmpty);
      expect(noResult.isDefaultScopeEmpty, isFalse);
      expect(noResult.activeFilterCount, greaterThan(0));
    });
  });
}

SalesOrderListCubit _buildCubit(SalesOrderRepository repo) {
  return SalesOrderListCubit(
    repository: repo,
    activeStoreContext: const _StoreContext('store-1'),
    nowBuilder: () => DateTime.utc(2026, 8, 12),
  );
}

app.SalesOrderListItemDto _dto(String id) {
  return app.SalesOrderListItemDto(
    salesOrderId: id,
    orderNumber: id.toUpperCase(),
    sourceVersion: 1,
    committedAt: DateTime.utc(2026, 8, 12),
    store: const app.StoreSnapshotDto(
      storeId: 'store-1',
      storeCode: 'HCM',
      displayName: 'CN HCM',
    ),
    total: const app.MoneyDto(amountMinor: 1000, currencyCode: 'VND'),
    lifecycleStatus: app.SalesOrderLifecycleStatus.completed,
    lockStatus: app.SalesOrderLockStatus.unlocked,
    settlementStatus: app.SalesSettlementStatus.paid,
    returnStatus: app.SalesOrderReturnProjectionStatus.none,
    eInvoiceStatus: app.IntegrationDeliveryStatus.delivered,
  );
}

app.PagedSalesOrderListDto _ok({
  List<app.SalesOrderListItemDto> items = const <app.SalesOrderListItemDto>[],
  bool hasMore = false,
  String? nextCursor,
}) {
  return app.PagedSalesOrderListDto(
    page: app.OpaqueCursorPageDto<app.SalesOrderListItemDto>(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
    ),
    totalMatching: items.length,
  );
}

sealed class _Resp {
  const _Resp();
}

final class _OkResp extends _Resp {
  const _OkResp(this.value);
  final app.PagedSalesOrderListDto value;
}

final class _Err extends _Resp {
  const _Err(this.error);
  final Object error;
}

/// Fake đơn hàng cho cubit danh sách: hàng đợi phản hồi, hoặc `listBuilder` / `searchBuilder`
/// khi test cần trả Future tự điều khiển; cũng ghi `listCalls` / `searchCalls` như fake dùng chung.
final class _ScriptedOrderRepository extends FakeSalesOrderRepository {
  _ScriptedOrderRepository({List<_Resp>? responses, this.listBuilder, this.searchBuilder})
    : _responses = responses ?? <_Resp>[_OkResp(_ok())];

  _ScriptedOrderRepository.failing(Object error)
    : _responses = <_Resp>[],
      listBuilder = null,
      searchBuilder = null {
    listError = error;
    searchError = error;
  }

  final List<_Resp> _responses;
  final Future<app.PagedSalesOrderListDto> Function(int call)? listBuilder;
  final Future<app.PagedSalesOrderListDto> Function()? searchBuilder;

  @override
  Future<app.PagedSalesOrderListDto> list({
    String? cursor,
    int pageSize = 50,
    app.SalesOrderListFilterInput? filter,
  }) async {
    listCalls.add((cursor: cursor, pageSize: pageSize, filter: filter));
    final e = listError;
    if (e != null) throw e;
    final builder = listBuilder;
    if (builder != null) return builder(listCalls.length);
    return _next();
  }

  @override
  Future<app.PagedSalesOrderListDto> search({
    required String searchText,
    String? cursor,
    int pageSize = 50,
    app.SalesOrderListFilterInput? filter,
  }) async {
    searchCalls.add((searchText: searchText, cursor: cursor, pageSize: pageSize, filter: filter));
    final e = searchError;
    if (e != null) throw e;
    final builder = searchBuilder;
    if (builder != null) return builder();
    return _next();
  }

  app.PagedSalesOrderListDto _next() {
    final response = _responses.isNotEmpty ? _responses.removeAt(0) : _OkResp(_ok());
    if (response is _OkResp) return response.value;
    if (response is _Err) throw response.error;
    throw StateError('Unsupported response');
  }
}

final class _StoreContext implements ISalesActiveStoreContext {
  const _StoreContext(this.storeId);

  final String storeId;

  @override
  String? get activeStoreId => storeId;

  @override
  Future<String> requireActiveStoreId() async => storeId;
}
