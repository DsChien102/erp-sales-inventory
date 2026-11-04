import 'package:equatable/equatable.dart';

enum ProductManualBasePriceStatus { initial, loading, success, failure }

class ProductManualBasePriceState extends Equatable {
  const ProductManualBasePriceState({
    this.status = ProductManualBasePriceStatus.initial,
    this.errorMessage,
  });

  final ProductManualBasePriceStatus status;
  final String? errorMessage;

  ProductManualBasePriceState copyWith({
    ProductManualBasePriceStatus? status,
    String? errorMessage,
  }) {
    return ProductManualBasePriceState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
