import 'package:equatable/equatable.dart';

import 'package:erp/features/sales/presentation/models/sales_order_draft/sales_draft_list_item_vm.dart';

enum SalesDraftScopeFilter { mine, all }

sealed class SalesDraftListState extends Equatable {
  const SalesDraftListState({
    this.query,
    this.isCreating = false,
    this.discardingDraftId,
    this.needsReload = false,
    this.actionMessage,
    this.totalCount = 0,
    this.scope = SalesDraftScopeFilter.mine,
    this.hasMore = false,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final String? query;
  final bool isCreating;
  final String? discardingDraftId;
  final bool needsReload;
  final String? actionMessage;

  /// Tổng số đơn nháp active của store (từ server) — không lọc theo scope hay từ khóa.
  final int totalCount;

  final SalesDraftScopeFilter scope;
  final bool hasMore;
  final String? nextCursor;
  final bool isLoadingMore;
  final String? loadMoreError;

  @override
  List<Object?> get props => [
    query,
    isCreating,
    discardingDraftId,
    needsReload,
    actionMessage,
    totalCount,
    scope,
    hasMore,
    nextCursor,
    isLoadingMore,
    loadMoreError,
  ];
}

final class SalesDraftListInitial extends SalesDraftListState {
  const SalesDraftListInitial();
}

final class SalesDraftListLoading extends SalesDraftListState {
  const SalesDraftListLoading({
    required this.items,
    this.isFirstLoad = true,
    super.query,
    super.isCreating,
    super.discardingDraftId,
    super.needsReload,
    super.actionMessage,
    super.totalCount,
    super.scope,
    super.hasMore,
    super.nextCursor,
    super.isLoadingMore,
    super.loadMoreError,
  });

  final List<SalesDraftListItemVm> items;
  final bool isFirstLoad;

  @override
  List<Object?> get props => [items, isFirstLoad, ...super.props];
}

final class SalesDraftListLoaded extends SalesDraftListState {
  const SalesDraftListLoaded({
    required this.items,
    required this.isDefaultEmpty,
    super.query,
    super.isCreating,
    super.discardingDraftId,
    super.needsReload,
    super.actionMessage,
    super.totalCount,
    super.scope,
    super.hasMore,
    super.nextCursor,
    super.isLoadingMore,
    super.loadMoreError,
  });

  final List<SalesDraftListItemVm> items;
  final bool isDefaultEmpty;

  SalesDraftListLoaded copyWith({
    List<SalesDraftListItemVm>? items,
    bool? isDefaultEmpty,
    String? query,
    bool? isCreating,
    String? discardingDraftId,
    bool? needsReload,
    String? actionMessage,
    int? totalCount,
    SalesDraftScopeFilter? scope,
    bool? hasMore,
    String? nextCursor,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearActionMessage = false,
    bool clearDiscarding = false,
    bool clearLoadMoreError = false,
  }) {
    return SalesDraftListLoaded(
      items: items ?? this.items,
      isDefaultEmpty: isDefaultEmpty ?? this.isDefaultEmpty,
      query: query ?? this.query,
      isCreating: isCreating ?? this.isCreating,
      discardingDraftId: clearDiscarding ? null : (discardingDraftId ?? this.discardingDraftId),
      needsReload: needsReload ?? this.needsReload,
      actionMessage: clearActionMessage ? null : (actionMessage ?? this.actionMessage),
      totalCount: totalCount ?? this.totalCount,
      scope: scope ?? this.scope,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [items, isDefaultEmpty, ...super.props];
}

final class SalesDraftListError extends SalesDraftListState {
  const SalesDraftListError(
    this.message, {
    super.query,
    super.isCreating,
    super.discardingDraftId,
    super.needsReload,
    super.actionMessage,
    super.totalCount,
    super.scope,
    super.hasMore,
    super.nextCursor,
    super.isLoadingMore,
    super.loadMoreError,
  });

  final String message;

  @override
  List<Object?> get props => [message, ...super.props];
}

final class SalesDraftListBlocked extends SalesDraftListState {
  const SalesDraftListBlocked({
    this.message = 'Không có quyền xem đơn nháp',
    super.scope,
  });

  final String message;

  @override
  List<Object?> get props => [message, ...super.props];
}
