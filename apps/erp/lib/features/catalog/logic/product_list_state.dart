import 'package:equatable/equatable.dart';
import 'package:erp/features/catalog/data/models.dart';

sealed class ProductListState extends Equatable {
  const ProductListState();

  @override
  List<Object?> get props => [];
}

final class ProductListInitial extends ProductListState {
  const ProductListInitial();
}

final class ProductListLoading extends ProductListState {
  const ProductListLoading({
    required this.criteria,
    required this.items,
    this.isFirstLoad = true,
  });

  final ProductSearchCriteria criteria;
  final List<ProductListItemDto> items;
  final bool isFirstLoad;

  @override
  List<Object?> get props => [criteria, items, isFirstLoad];
}

final class ProductListLoaded extends ProductListState {
  const ProductListLoaded({
    required this.criteria,
    required this.items,
    required this.totalCount,
    required this.hasReachedMax,
  });

  final ProductSearchCriteria criteria;
  final List<ProductListItemDto> items;
  final int totalCount;
  final bool hasReachedMax;

  @override
  List<Object?> get props => [criteria, items, totalCount, hasReachedMax];
}

final class ProductListError extends ProductListState {
  const ProductListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
