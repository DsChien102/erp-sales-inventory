import 'dart:async';

import 'package:erp/features/sales/presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart' as app;
import 'package:vet45_shared_application/application.dart';

import '../../support/module_backed_sales_repositories.dart';

void main() {
  group('SalesOrderListCubit server state', () {
    test('loadInitial binds tenant actor store and cursor null', () async {
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      final query = module.queries.single as app.ListSalesOrdersQuery;
      expect(query.tenantId, 'tenant-1');
      expect(query.actorId, 'actor-1');
      expect(query.filter?.storeId, 'store-1');
      expect(query.cursor, isNull);
    });

    test('searchByKeyword sends SearchSalesOrdersQuery and resets cursor', () async {
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.searchByKeyword('SO-001');

      final query = module.queries.single as app.SearchSalesOrdersQuery;
      expect(query.searchText, 'SO-001');
      expect(query.cursor, isNull);
      expect(query.filter?.storeId, 'store-1');
    });

    test('loadMore uses nextCursor and dedupes ids', () async {
      final module = _RecordingSalesModule(
        responses: [
          _OkResp(_ok(items: [_dto('so-1')], hasMore: true, nextCursor: 'c2')),
          _OkResp(_ok(items: [_dto('so-1'), _dto('so-2')], hasMore: false)),
        ],
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await cubit.loadMore();

      final second = module.queries.last as app.ListSalesOrdersQuery;
      expect(second.cursor, 'c2');
      final state = cubit.state as SalesOrderListLoaded;
      expect(state.items.map((e) => e.salesOrderId).toList(), ['so-1', 'so-2']);
      expect(state.hasMore, isFalse);
    });

    test('loadMore error keeps rows and sets loadMoreError', () async {
      final module = _RecordingSalesModule(
        responses: [
          _OkResp(_ok(items: [_dto('so-1')], hasMore: true, nextCursor: 'c2')),
          const _Err(app.SalesContractException('TRANSPORT_ERROR', message: 'network down')),
        ],
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await cubit.loadMore();

      final state = cubit.state as SalesOrderListLoaded;
      expect(state.items, hasLength(1));
      expect(state.loadMoreError, 'Không thể tải thêm đơn hàng. Vui lòng thử lại.');
      expect(state.isLoadingMore, isFalse);
    });

    test('stale response does not override newer generation', () async {
      final module = _StaleAwareModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      final a = cubit.loadInitial();
      final b = cubit.searchByKeyword('new');

      module.searchCompleter.complete(_ok(items: [_dto('so-new')]));
      await b;
      module.listCompleter.complete(_ok(items: [_dto('so-old')]));
      await a;

      final state = cubit.state as SalesOrderListLoaded;
      expect(state.items.single.salesOrderId, 'so-new');
      expect(state.requestGeneration, 2);
    });

    test('permission denied maps to blocked state', () async {
      final module = _PermissionDeniedModule();
      final cubit = _buildCubit(module: module);
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
      final module = _ContractErrorModule('DATA_SCOPE_DENIED');
      final cubit = _buildCubit(module: module);
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
      final module = _ContractErrorModule('PROJECTION_PENDING');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      final state = cubit.state as SalesOrderListError;
      expect(state.message, 'Không thể tải danh sách đơn hàng.');
    });

    test('transport retryable error maps to generic list error', () async {
      final module = _ContractErrorModule('TRANSPORT_RETRYABLE');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      final state = cubit.state as SalesOrderListError;
      expect(state.message, 'Không thể tải danh sách đơn hàng.');
    });

    test('load_error_shows_accented_message', () async {
      final module = _ContractErrorModule('UNKNOWN_ERROR');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.loadInitial();

      final state = cubit.state as SalesOrderListError;
      expect(state.message, 'Không thể tải danh sách đơn hàng.');
    });

    test('load_more_error_never_shows_server_message', () async {
      final module = _RecordingSalesModule(
        responses: [
          _OkResp(_ok(items: [_dto('so-1')], hasMore: true, nextCursor: 'c2')),
          const _Err(app.SalesContractException('UNKNOWN', message: 'raw server explosion')),
        ],
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await cubit.loadMore();

      final state = cubit.state as SalesOrderListLoaded;
      expect(state.loadMoreError, 'Không thể tải thêm đơn hàng. Vui lòng thử lại.');
      expect(state.loadMoreError, isNot(contains('server')));
    });

    test('blocked_on_no_permission', () async {
      final module = _PermissionDeniedModule();
      final cubit = _buildCubit(module: module);
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
      final module = _ContractErrorModule('DATA_SCOPE_DENIED');
      final cubit = _buildCubit(module: module);
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
      final module = _RecordingSalesModule(
        responses: [
          _OkResp(_ok(items: [_dto('so-1')])),
          _OkResp(_ok(items: [_dto('so-2')])),
        ],
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await cubit.applyFilters(lifecycleFilter: SalesOrderListLifecycleFilter.completed);

      expect(module.queries, hasLength(2));
      final query = module.queries.last as app.ListSalesOrdersQuery;
      expect(query.cursor, isNull);
      expect(query.filter?.storeId, 'store-1');
      expect(query.filter?.lifecycleStatus, app.SalesOrderLifecycleStatus.completed);
    });

    test('applyFilters retains previous items and is not a first-load skeleton', () async {
      final module = _DelayedSecondListModule(first: _ok(items: [_dto('so-1')]));
      final cubit = _buildCubit(module: module);
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

      module.second.complete(_ok(items: [_dto('so-2')]));
      await pending;

      final loaded = cubit.state as SalesOrderListLoaded;
      expect(loaded.items.single.salesOrderId, 'so-2');
    });

    test('empty default scope is distinct from filtered no-result', () async {
      final module = _RecordingSalesModule(
        responses: [_OkResp(_ok()), _OkResp(_ok())],
      );
      final cubit = _buildCubit(module: module);
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

SalesOrderListCubit _buildCubit({required app.ISalesModule module}) {
  return SalesOrderListCubit(
    repository: ModuleBackedSalesOrderRepository(module),
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

final class _RecordingSalesModule implements app.ISalesModule {
  _RecordingSalesModule({List<_Resp>? responses})
    : _responses = responses ?? <_Resp>[_OkResp(_ok())];

  final List<_Resp> _responses;
  final List<Object> queries = <Object>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('list cubit must not execute commands');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    final response = _responses.isNotEmpty ? _responses.removeAt(0) : _OkResp(_ok());
    if (response is _OkResp) return response.value as TResult;
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

final class _PermissionDeniedModule implements app.ISalesModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    throw const app.SalesContractException('PERMISSION_DENIED');
  }
}

final class _ContractErrorModule implements app.ISalesModule {
  const _ContractErrorModule(this.code);

  final String code;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    throw app.SalesContractException(code);
  }
}

final class _DelayedSecondListModule implements app.ISalesModule {
  _DelayedSecondListModule({required this.first});

  final app.PagedSalesOrderListDto first;
  final Completer<app.PagedSalesOrderListDto> second = Completer();
  int _calls = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    _calls++;
    if (_calls == 1) return Future<TResult>.value(first as TResult);
    return second.future as Future<TResult>;
  }
}

final class _StaleAwareModule implements app.ISalesModule {
  final Completer<app.PagedSalesOrderListDto> listCompleter = Completer();
  final Completer<app.PagedSalesOrderListDto> searchCompleter = Completer();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is app.SearchSalesOrdersQuery) {
      return searchCompleter.future as Future<TResult>;
    }
    return listCompleter.future as Future<TResult>;
  }
}
