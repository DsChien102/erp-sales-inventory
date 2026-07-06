import 'package:equatable/equatable.dart';
import 'package:vet45_catalog_application/application.dart';

enum ProductControlCenterStatus { initial, loading, success, failure }

final class ProductControlCenterState extends Equatable {
  const ProductControlCenterState({
    this.status = ProductControlCenterStatus.initial,
    this.readinessView,
    this.errorMessage,
  });

  final ProductControlCenterStatus status;
  final ProductReadinessViewDto? readinessView;
  final String? errorMessage;

  ProductControlCenterState copyWith({
    ProductControlCenterStatus? status,
    ProductReadinessViewDto? readinessView,
    String? errorMessage,
  }) {
    return ProductControlCenterState(
      status: status ?? this.status,
      readinessView: readinessView ?? this.readinessView,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, readinessView, errorMessage];
}
