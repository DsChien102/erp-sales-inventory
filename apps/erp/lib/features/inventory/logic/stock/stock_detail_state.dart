import 'package:equatable/equatable.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';

enum StockDetailStatus {
  loading,
  ready,
  denied,
  loadError,
}

class StockDetailState extends Equatable {
  final StockDetailStatus status;
  final String? productId;
  final StockDetail? data;
  final bool stale;
  final AppException? error;

  const StockDetailState({
    this.status = StockDetailStatus.loading,
    this.productId,
    this.data,
    this.stale = false,
    this.error,
  });

  StockDetailState copyWith({
    StockDetailStatus? status,
    String? productId,
    StockDetail? data,
    bool? stale,
    AppException? error,
    bool clearError = false,
  }) {
    return StockDetailState(
      status: status ?? this.status,
      productId: productId ?? this.productId,
      data: data ?? this.data,
      stale: stale ?? this.stale,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, productId, data, stale, error];
}

