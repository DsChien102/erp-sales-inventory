import 'package:equatable/equatable.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/stock/stock_list_rules.dart';

enum StockListStatus {
  loading,
  ready,
  empty,
  denied,
  loadError,
}

class StockListState extends Equatable {
  final StockListStatus status;
  final StockOverview? data;
  final StockFilter filter;
  final String query;
  final bool stale;
  final String? selectedProductId;
  final AppException? error;

  const StockListState({
    this.status = StockListStatus.loading,
    this.data,
    this.filter = StockFilter.all,
    this.query = '',
    this.stale = false,
    this.selectedProductId,
    this.error,
  });

  List<StockOverviewItem> get visible => data == null
      ? const []
      : visibleProducts(data!.products, filter, query);

  StockOverviewItem? get selected {
    final list = visible;
    if (list.isEmpty) return null;
    if (selectedProductId != null) {
      for (final item in list) {
        if (item.productId == selectedProductId) return item;
      }
    }
    return list.first;
  }

  StockListState copyWith({
    StockListStatus? status,
    StockOverview? data,
    StockFilter? filter,
    String? query,
    bool? stale,
    String? selectedProductId,
    bool clearSelectedProductId = false,
    AppException? error,
    bool clearError = false,
  }) {
    return StockListState(
      status: status ?? this.status,
      data: data ?? this.data,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      stale: stale ?? this.stale,
      selectedProductId: clearSelectedProductId
          ? null
          : (selectedProductId ?? this.selectedProductId),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        status,
        data,
        filter,
        query,
        stale,
        selectedProductId,
        error,
      ];
}

