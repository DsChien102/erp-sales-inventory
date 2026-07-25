import 'package:equatable/equatable.dart';
import 'package:vet45_pricing_application/application.dart';

import '../models/price_rule_list_filters.dart';

/// Trạng thái cubit danh sách giá riêng (S2 — SG-01).
sealed class PriceRuleListState extends Equatable {
  const PriceRuleListState({
    this.items = const [],
    this.query,
    this.quickFilter = CustomerPriceRuleQuickFilter.all,
    this.advancedFilter = PriceRuleAdvancedFilter.empty,
    this.sortOption = PriceRuleSortOption.updatedAtDesc,
    this.hasReachedMax = false,
    this.canCreate = false,
    this.canImport = false,
    this.totalCount = 0,
  });

  final List<CustomerPriceRuleListItemDto> items;
  final String? query;
  final CustomerPriceRuleQuickFilter quickFilter;
  final PriceRuleAdvancedFilter advancedFilter;
  final PriceRuleSortOption sortOption;
  final bool hasReachedMax;
  final bool canCreate;
  final bool canImport;
  final int totalCount;

  @override
  List<Object?> get props => [
    items,
    query,
    quickFilter,
    advancedFilter,
    sortOption,
    hasReachedMax,
    canCreate,
    canImport,
    totalCount,
  ];
}

final class PriceRuleListInitial extends PriceRuleListState {
  const PriceRuleListInitial() : super();
}

final class PriceRuleListLoading extends PriceRuleListState {
  const PriceRuleListLoading({
    super.items,
    super.query,
    super.quickFilter,
    super.advancedFilter,
    super.sortOption,
    super.hasReachedMax,
    super.canCreate,
    super.canImport,
    super.totalCount,
    this.isFirstLoad = true,
  });

  final bool isFirstLoad;

  @override
  List<Object?> get props => [...super.props, isFirstLoad];
}

final class PriceRuleListLoaded extends PriceRuleListState {
  const PriceRuleListLoaded({
    required super.items,
    required super.totalCount,
    super.query,
    super.quickFilter,
    super.advancedFilter,
    super.sortOption,
    super.hasReachedMax,
    super.canCreate,
    super.canImport,
  });
}

final class PriceRuleListError extends PriceRuleListState {
  const PriceRuleListError({
    required this.message,
    super.items,
    super.query,
    super.quickFilter,
    super.advancedFilter,
    super.sortOption,
    super.canCreate,
    super.canImport,
    super.totalCount,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}

final class PriceRuleListNoPermission extends PriceRuleListState {
  const PriceRuleListNoPermission({
    super.query,
    super.quickFilter,
    super.advancedFilter,
    super.sortOption,
  });
}
