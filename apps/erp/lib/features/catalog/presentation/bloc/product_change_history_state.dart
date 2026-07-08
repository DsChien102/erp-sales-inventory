import 'package:equatable/equatable.dart';
import 'package:vet45_catalog_application/application.dart';

enum ProductChangeHistoryStatus { initial, loading, success, failure }

class ProductChangeHistoryState extends Equatable {
  final ProductChangeHistoryStatus status;
  final List<ProductChangeHistoryEntryDto> items;
  final int totalCount;
  final bool hasReachedMax;
  final String? errorMessage;
  final int offset;

  const ProductChangeHistoryState({
    this.status = ProductChangeHistoryStatus.initial,
    this.items = const [],
    this.totalCount = 0,
    this.hasReachedMax = false,
    this.errorMessage,
    this.offset = 0,
  });

  ProductChangeHistoryState copyWith({
    ProductChangeHistoryStatus? status,
    List<ProductChangeHistoryEntryDto>? items,
    int? totalCount,
    bool? hasReachedMax,
    String? errorMessage,
    int? offset,
  }) {
    return ProductChangeHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [status, items, totalCount, hasReachedMax, errorMessage, offset];
}
