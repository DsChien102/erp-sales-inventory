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
  });

  final String? query;
  final bool isCreating;
  final String? discardingDraftId;
  final bool needsReload;
  final String? actionMessage;

  /// Tổng số đơn nháp đã tải của store — không lọc theo scope hay từ khóa.
  final int totalCount;

  @override
  List<Object?> get props => [
    query,
    isCreating,
    discardingDraftId,
    needsReload,
    actionMessage,
    totalCount,
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
  });

  final List<SalesDraftListItemVm> items;
  final bool isDefaultEmpty;

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
  });

  final String message;

  @override
  List<Object?> get props => [message, ...super.props];
}

final class SalesDraftListBlocked extends SalesDraftListState {
  const SalesDraftListBlocked({
    this.message = 'Không có quyền xem đơn nháp',
  });

  final String message;

  @override
  List<Object?> get props => [message, ...super.props];
}
