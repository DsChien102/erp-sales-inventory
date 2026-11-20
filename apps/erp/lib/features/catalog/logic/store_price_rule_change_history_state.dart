import 'package:equatable/equatable.dart';
import 'package:erp/features/catalog/data/models.dart';

abstract class StorePriceRuleChangeHistoryState extends Equatable {
  const StorePriceRuleChangeHistoryState();

  @override
  List<Object?> get props => [];
}

class StorePriceRuleChangeHistoryInitial extends StorePriceRuleChangeHistoryState {}

class StorePriceRuleChangeHistoryLoading extends StorePriceRuleChangeHistoryState {}

class StorePriceRuleChangeHistoryLoaded extends StorePriceRuleChangeHistoryState {
  const StorePriceRuleChangeHistoryLoaded({
    required this.items,
    required this.totalCount,
    this.isLoadingMore = false,
  });

  final List<StorePriceRuleChangeHistoryEntryDto> items;
  final int totalCount;
  final bool isLoadingMore;

  bool get canLoadMore => items.length < totalCount;

  @override
  List<Object?> get props => [items, totalCount, isLoadingMore];
}

class StorePriceRuleChangeHistoryError extends StorePriceRuleChangeHistoryState {
  const StorePriceRuleChangeHistoryError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
