import 'package:equatable/equatable.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_list_filters.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_list_item_vm.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_saved_search_preset.dart';

sealed class SalesOrderListState extends Equatable {
  const SalesOrderListState({
    this.query,
    this.preset = SalesOrderSavedSearchPreset.all,
    this.timeFilter = SalesOrderListTimeFilter.all,
    this.lifecycleFilter = SalesOrderListLifecycleFilter.all,
    this.settlementFilter = SalesOrderListSettlementFilter.all,
    this.postSaleFilter = SalesOrderListPostSaleFilter.all,
    this.eInvoiceFilter = SalesOrderListEInvoiceFilter.all,
    this.presetCounts = const <SalesOrderSavedSearchPreset, int>{},
    this.totalAvailable = 0,
  });

  final String? query;
  final SalesOrderSavedSearchPreset preset;
  final SalesOrderListTimeFilter timeFilter;
  final SalesOrderListLifecycleFilter lifecycleFilter;
  final SalesOrderListSettlementFilter settlementFilter;
  final SalesOrderListPostSaleFilter postSaleFilter;
  final SalesOrderListEInvoiceFilter eInvoiceFilter;
  final Map<SalesOrderSavedSearchPreset, int> presetCounts;
  final int totalAvailable;

  List<SalesOrderListItemVm> get items => const <SalesOrderListItemVm>[];

  int get activeFilterCount =>
      (preset != SalesOrderSavedSearchPreset.all ? 1 : 0) +
      (timeFilter != SalesOrderListTimeFilter.all ? 1 : 0) +
      (lifecycleFilter != SalesOrderListLifecycleFilter.all ? 1 : 0) +
      (settlementFilter != SalesOrderListSettlementFilter.all ? 1 : 0) +
      (postSaleFilter != SalesOrderListPostSaleFilter.all ? 1 : 0) +
      (eInvoiceFilter != SalesOrderListEInvoiceFilter.all ? 1 : 0);

  @override
  List<Object?> get props => [
    query,
    preset,
    timeFilter,
    lifecycleFilter,
    settlementFilter,
    postSaleFilter,
    eInvoiceFilter,
    presetCounts,
    totalAvailable,
  ];
}

final class SalesOrderListInitial extends SalesOrderListState {
  const SalesOrderListInitial();
}

final class SalesOrderListLoading extends SalesOrderListState {
  const SalesOrderListLoading({
    required this.items,
    this.isFirstLoad = true,
    super.query,
    super.preset,
    super.timeFilter,
    super.lifecycleFilter,
    super.settlementFilter,
    super.postSaleFilter,
    super.eInvoiceFilter,
    super.presetCounts,
    super.totalAvailable,
  });

  @override
  final List<SalesOrderListItemVm> items;
  final bool isFirstLoad;

  @override
  List<Object?> get props => [items, isFirstLoad, ...super.props];
}

final class SalesOrderListLoaded extends SalesOrderListState {
  const SalesOrderListLoaded({
    required this.items,
    required this.hasMore,
    required this.requestGeneration,
    this.nextCursor,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.totalMatching = 0,
    this.isDefaultScopeEmpty = false,
    super.query,
    super.preset,
    super.timeFilter,
    super.lifecycleFilter,
    super.settlementFilter,
    super.postSaleFilter,
    super.eInvoiceFilter,
    super.presetCounts,
    super.totalAvailable,
  });

  @override
  final List<SalesOrderListItemVm> items;
  final bool hasMore;
  final String? nextCursor;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? loadMoreError;
  final int requestGeneration;
  final int totalMatching;
  final bool isDefaultScopeEmpty;

  @override
  List<Object?> get props => [
    items,
    hasMore,
    nextCursor,
    isRefreshing,
    isLoadingMore,
    loadMoreError,
    requestGeneration,
    totalMatching,
    isDefaultScopeEmpty,
    ...super.props,
  ];
}

final class SalesOrderListError extends SalesOrderListState {
  const SalesOrderListError(
    this.message, {
    super.query,
    super.preset,
    super.timeFilter,
    super.lifecycleFilter,
    super.settlementFilter,
    super.postSaleFilter,
    super.eInvoiceFilter,
    super.presetCounts,
    super.totalAvailable,
  });

  final String message;

  @override
  List<Object?> get props => [message, ...super.props];
}

final class SalesOrderListBlocked extends SalesOrderListState {
  const SalesOrderListBlocked({this.message = 'Không có quyền xem đơn hàng'});

  final String message;

  @override
  List<Object?> get props => [message, ...super.props];
}
