import 'package:equatable/equatable.dart';
import 'package:vet45_catalog_application/application.dart';

enum ProductControlCenterStatus { initial, loading, success, failure }

final class ProductControlCenterState extends Equatable {
  const ProductControlCenterState({
    this.status = ProductControlCenterStatus.initial,
    this.controlCenter,
    this.readinessView,
    this.errorMessage,
  });

  final ProductControlCenterStatus status;
  final ProductControlCenterDto? controlCenter;
  final ProductReadinessViewDto? readinessView;
  final String? errorMessage;

  ProductControlCenterState copyWith({
    ProductControlCenterStatus? status,
    ProductControlCenterDto? controlCenter,
    ProductReadinessViewDto? readinessView,
    String? errorMessage,
  }) {
    return ProductControlCenterState(
      status: status ?? this.status,
      controlCenter: controlCenter ?? this.controlCenter,
      readinessView: readinessView ?? this.readinessView,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, controlCenter, readinessView, errorMessage];
}
