import 'package:equatable/equatable.dart';

enum ProductStockAdjustmentStatus { initial, loading, success, failure }

class ProductStockAdjustmentState extends Equatable {
  const ProductStockAdjustmentState({
    this.status = ProductStockAdjustmentStatus.initial,
    this.errorMessage,
  });

  final ProductStockAdjustmentStatus status;
  final String? errorMessage;

  ProductStockAdjustmentState copyWith({
    ProductStockAdjustmentStatus? status,
    String? errorMessage,
  }) {
    return ProductStockAdjustmentState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

