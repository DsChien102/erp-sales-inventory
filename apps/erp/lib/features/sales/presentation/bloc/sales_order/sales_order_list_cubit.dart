import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../models/sales_order/sales_order_list_filters.dart';
import '../../models/sales_order/sales_order_list_item_vm.dart';
import '../../models/sales_order/sales_order_saved_search_preset.dart';
import '../../support/i_sales_active_store_context.dart';
import '../../support/sales_order_list_mapper.dart';
import 'sales_order_list_state.dart';

final class SalesOrderListCubit extends Cubit<SalesOrderListState> {
  SalesOrderListCubit({
    required ISalesModule salesModule,
    required IExecutionContext executionContext,
    required ISalesActiveStoreContext activeStoreContext,
    DateTime? Function()? nowBuilder,
  }) : _salesModule = salesModule,
       _executionContext = executionContext,
       _activeStoreContext = activeStoreContext,
       _nowBuilder = nowBuilder ?? DateTime.now,
       super(const SalesOrderListInitial());

  final ISalesModule _salesModule;
  final IExecutionContext _executionContext;
  final ISalesActiveStoreContext _activeStoreContext;
  final DateTime? Function() _nowBuilder;

  String? _query;
  SalesOrderSavedSearchPreset _preset = SalesOrderSavedSearchPreset.all;
  SalesOrderListTimeFilter _timeFilter = SalesOrderListTimeFilter.all;
  SalesOrderListLifecycleFilter _lifecycleFilter = SalesOrderListLifecycleFilter.all;
  SalesOrderListSettlementFilter _settlementFilter = SalesOrderListSettlementFilter.all;
  SalesOrderListPostSaleFilter _postSaleFilter = SalesOrderListPostSaleFilter.all;
  SalesOrderListEInvoiceFilter _eInvoiceFilter = SalesOrderListEInvoiceFilter.all;
  int _requestGeneration = 0;

  Future<void> load({bool isRefresh = false}) {
    return isRefresh ? refresh() : loadInitial();
  }

  Future<void> loadInitial() async {
    await _runFreshRequest(isRefresh: false);
  }

  Future<void> refresh() async {
    await _runFreshRequest(isRefresh: true);
  }

  Future<void> _runFreshRequest({required bool isRefresh}) async {
    if (isClosed) return;
    final current = state;
    final generation = ++_requestGeneration;
    final querySnapshot = _query;
    final retained = current.items;
    final inlineRefresh = isRefresh && retained.isNotEmpty;
    if (inlineRefresh) {
      emit(
        SalesOrderListLoaded(
          items: retained,
          hasMore: current is SalesOrderListLoaded ? current.hasMore : false,
          nextCursor: current is SalesOrderListLoaded ? current.nextCursor : null,
          isRefreshing: true,
          requestGeneration: generation,
          query: _query,
          preset: _preset,
          timeFilter: _timeFilter,
          lifecycleFilter: _lifecycleFilter,
          settlementFilter: _settlementFilter,
          postSaleFilter: _postSaleFilter,
          eInvoiceFilter: _eInvoiceFilter,
          presetCounts: current.presetCounts,
          totalAvailable: current.totalAvailable,
        ),
      );
    } else {
      emit(
        SalesOrderListLoading(
          items: retained,
          isFirstLoad: retained.isEmpty,
          query: _query,
          preset: _preset,
          timeFilter: _timeFilter,
          lifecycleFilter: _lifecycleFilter,
          settlementFilter: _settlementFilter,
          postSaleFilter: _postSaleFilter,
          eInvoiceFilter: _eInvoiceFilter,
          presetCounts: current.presetCounts,
          totalAvailable: current.totalAvailable,
        ),
      );
    }

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final storeId = await _activeStoreContext.requireActiveStoreId();
      if (isClosed) return;
      final result = await _executeListQuery(
        tenantId: tenantId,
        actorId: actorId,
        storeId: storeId,
        queryText: querySnapshot,
        cursor: null,
      );
      if (isClosed || generation != _requestGeneration) return;
      emit(_toLoadedState(result: result, generation: generation));
    } catch (error) {
      if (isClosed) return;
      final contractError = _asContractException(error);
      if (contractError != null &&
          (contractError.code == 'PERMISSION_DENIED' ||
              contractError.code == 'DATA_SCOPE_DENIED')) {
        emit(SalesOrderListBlocked(message: contractError.message ?? contractError.code));
        return;
      }
      if (generation == _requestGeneration) {
        emit(_error('Khong the tai danh sach don hang'));
      }
    }
  }

  Future<void> searchByKeyword(String query) async {
    _query = query.trim().isEmpty ? null : query.trim();
    await _runFreshRequest(isRefresh: false);
  }

  Future<void> selectPreset(SalesOrderSavedSearchPreset preset) async {
    if (preset == _preset) return;
    await applyFilters(preset: preset);
  }

  Future<void> applyFilters({
    SalesOrderSavedSearchPreset? preset,
    SalesOrderListTimeFilter? timeFilter,
    SalesOrderListLifecycleFilter? lifecycleFilter,
    SalesOrderListSettlementFilter? settlementFilter,
    SalesOrderListPostSaleFilter? postSaleFilter,
    SalesOrderListEInvoiceFilter? eInvoiceFilter,
  }) async {
    if (isClosed) return;
    if (preset != null) _preset = preset;
    if (timeFilter != null) _timeFilter = timeFilter;
    if (lifecycleFilter != null) _lifecycleFilter = lifecycleFilter;
    if (settlementFilter != null) _settlementFilter = settlementFilter;
    if (postSaleFilter != null) _postSaleFilter = postSaleFilter;
    if (eInvoiceFilter != null) _eInvoiceFilter = eInvoiceFilter;
    await _runFreshRequest(isRefresh: false);
  }

  Future<void> clearFilters() async {
    await applyFilters(
      preset: SalesOrderSavedSearchPreset.all,
      timeFilter: SalesOrderListTimeFilter.all,
      lifecycleFilter: SalesOrderListLifecycleFilter.all,
      settlementFilter: SalesOrderListSettlementFilter.all,
      postSaleFilter: SalesOrderListPostSaleFilter.all,
      eInvoiceFilter: SalesOrderListEInvoiceFilter.all,
    );
  }

  void clearSearch() {
    _query = null;
    loadInitial();
  }

  Future<void> loadMore() async {
    if (isClosed) return;
    final current = state;
    if (current is! SalesOrderListLoaded) return;
    if (current.isLoadingMore || !current.hasMore) return;
    final cursor = current.nextCursor;
    if (cursor == null || cursor.isEmpty) return;

    final generation = _requestGeneration;
    emit(
      SalesOrderListLoaded(
        items: current.items,
        hasMore: current.hasMore,
        nextCursor: current.nextCursor,
        isRefreshing: false,
        isLoadingMore: true,
        loadMoreError: null,
        requestGeneration: current.requestGeneration,
        totalMatching: current.totalMatching,
        isDefaultScopeEmpty: current.isDefaultScopeEmpty,
        query: _query,
        preset: _preset,
        timeFilter: _timeFilter,
        lifecycleFilter: _lifecycleFilter,
        settlementFilter: _settlementFilter,
        postSaleFilter: _postSaleFilter,
        eInvoiceFilter: _eInvoiceFilter,
        presetCounts: current.presetCounts,
        totalAvailable: current.totalAvailable,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final storeId = await _activeStoreContext.requireActiveStoreId();
      if (isClosed || generation != _requestGeneration) return;
      final result = await _executeListQuery(
        tenantId: tenantId,
        actorId: actorId,
        storeId: storeId,
        queryText: _query,
        cursor: cursor,
      );
      if (isClosed || generation != _requestGeneration) return;
      final incoming = result.page.items.map(SalesOrderListMapper.toVm).toList(growable: false);
      final merged = _mergeUniqueById(current.items, incoming);
      emit(
        SalesOrderListLoaded(
          items: merged,
          hasMore: result.page.hasMore,
          nextCursor: result.page.nextCursor,
          requestGeneration: current.requestGeneration,
          totalMatching: result.totalMatching ?? merged.length,
          isDefaultScopeEmpty: merged.isEmpty && _isDefaultScope,
          query: _query,
          preset: _preset,
          timeFilter: _timeFilter,
          lifecycleFilter: _lifecycleFilter,
          settlementFilter: _settlementFilter,
          postSaleFilter: _postSaleFilter,
          eInvoiceFilter: _eInvoiceFilter,
          presetCounts: SalesOrderListMapper.presetCountsFrom(
            result.facets,
            totalAvailable: result.totalMatching ?? merged.length,
          ),
          totalAvailable: result.totalMatching ?? merged.length,
        ),
      );
    } on SalesContractException catch (error) {
      if (isClosed || generation != _requestGeneration) return;
      emit(_withLoadMoreError(current, error.message ?? 'Khong the tai them danh sach don hang'));
    } catch (_) {
      if (isClosed || generation != _requestGeneration) return;
      emit(_withLoadMoreError(current, 'Khong the tai them danh sach don hang'));
    }
  }

  Future<PagedSalesOrderListDto> _executeListQuery({
    required String tenantId,
    required String actorId,
    required String storeId,
    required String? queryText,
    required String? cursor,
  }) {
    final filter = SalesOrderListMapper.toFilterInput(
      preset: _preset,
      timeFilter: _timeFilter,
      lifecycleFilter: _lifecycleFilter,
      settlementFilter: _settlementFilter,
      postSaleFilter: _postSaleFilter,
      eInvoiceFilter: _eInvoiceFilter,
      now: _nowBuilder() ?? DateTime.now(),
      storeId: storeId,
    );
    final q = queryText;
    if (q == null || q.isEmpty) {
      return _salesModule.executeQueryAsync(
        ListSalesOrdersQuery(
          tenantId: tenantId,
          actorId: actorId,
          cursor: cursor,
          pageSize: 50,
          filter: filter,
        ),
      );
    }
    return _salesModule.executeQueryAsync(
      SearchSalesOrdersQuery(
        tenantId: tenantId,
        actorId: actorId,
        searchText: q,
        cursor: cursor,
        pageSize: 50,
        filter: filter,
      ),
    );
  }

  SalesContractException? _asContractException(Object error) {
    if (error is SalesContractException) return error;
    return null;
  }

  SalesOrderListLoaded _toLoadedState({
    required PagedSalesOrderListDto result,
    required int generation,
  }) {
    final items = result.page.items.map(SalesOrderListMapper.toVm).toList(growable: false);
    final total = result.totalMatching ?? items.length;
    return SalesOrderListLoaded(
      items: items,
      hasMore: result.page.hasMore,
      nextCursor: result.page.nextCursor,
      requestGeneration: generation,
      totalMatching: total,
      isDefaultScopeEmpty: items.isEmpty && _isDefaultScope,
      query: _query,
      preset: _preset,
      timeFilter: _timeFilter,
      lifecycleFilter: _lifecycleFilter,
      settlementFilter: _settlementFilter,
      postSaleFilter: _postSaleFilter,
      eInvoiceFilter: _eInvoiceFilter,
      presetCounts: SalesOrderListMapper.presetCountsFrom(result.facets, totalAvailable: total),
      totalAvailable: total,
    );
  }

  SalesOrderListLoaded _withLoadMoreError(SalesOrderListLoaded current, String message) {
    return SalesOrderListLoaded(
      items: current.items,
      hasMore: current.hasMore,
      nextCursor: current.nextCursor,
      isRefreshing: false,
      isLoadingMore: false,
      loadMoreError: message,
      requestGeneration: current.requestGeneration,
      totalMatching: current.totalMatching,
      isDefaultScopeEmpty: current.isDefaultScopeEmpty,
      query: _query,
      preset: _preset,
      timeFilter: _timeFilter,
      lifecycleFilter: _lifecycleFilter,
      settlementFilter: _settlementFilter,
      postSaleFilter: _postSaleFilter,
      eInvoiceFilter: _eInvoiceFilter,
      presetCounts: current.presetCounts,
      totalAvailable: current.totalAvailable,
    );
  }

  List<SalesOrderListItemVm> _mergeUniqueById(
    List<SalesOrderListItemVm> existing,
    List<SalesOrderListItemVm> incoming,
  ) {
    final seen = <String>{for (final item in existing) item.salesOrderId};
    final merged = <SalesOrderListItemVm>[...existing];
    for (final item in incoming) {
      if (seen.add(item.salesOrderId)) merged.add(item);
    }
    return merged;
  }

  bool get _isDefaultScope {
    final query = _query;
    return (query == null || query.isEmpty) &&
        _preset == SalesOrderSavedSearchPreset.all &&
        _timeFilter == SalesOrderListTimeFilter.all &&
        _lifecycleFilter == SalesOrderListLifecycleFilter.all &&
        _settlementFilter == SalesOrderListSettlementFilter.all &&
        _postSaleFilter == SalesOrderListPostSaleFilter.all &&
        _eInvoiceFilter == SalesOrderListEInvoiceFilter.all;
  }

  SalesOrderListError _error(String message) {
    return SalesOrderListError(
      message,
      query: _query,
      preset: _preset,
      timeFilter: _timeFilter,
      lifecycleFilter: _lifecycleFilter,
      settlementFilter: _settlementFilter,
      postSaleFilter: _postSaleFilter,
      eInvoiceFilter: _eInvoiceFilter,
      presetCounts: state.presetCounts,
      totalAvailable: state.totalAvailable,
    );
  }
}
