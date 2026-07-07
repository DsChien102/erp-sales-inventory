import 'package:equatable/equatable.dart';
import 'package:vet45_catalog_application/application.dart';

enum ProductSoftDeleteStatus { initial, checkingEligibility, eligibilityChecked, deleting, success, error }

class ProductSoftDeleteState extends Equatable {
  const ProductSoftDeleteState({
    this.status = ProductSoftDeleteStatus.initial,
    this.eligibility,
    this.errorMessage,
  });

  final ProductSoftDeleteStatus status;
  final ProductDeletionEligibilityDto? eligibility;
  final String? errorMessage;

  ProductSoftDeleteState copyWith({
    ProductSoftDeleteStatus? status,
    ProductDeletionEligibilityDto? eligibility,
    String? errorMessage,
  }) {
    return ProductSoftDeleteState(
      status: status ?? this.status,
      eligibility: eligibility ?? this.eligibility,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, eligibility, errorMessage];
}
