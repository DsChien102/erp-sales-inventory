import 'package:equatable/equatable.dart';
import 'package:vet45_catalog_application/application.dart';

abstract class ProductPriceBandsState extends Equatable {
  const ProductPriceBandsState();

  @override
  List<Object?> get props => [];
}

class ProductPriceBandsInitial extends ProductPriceBandsState {}

class ProductPriceBandsLoading extends ProductPriceBandsState {}

class ProductPriceBandsMissingBaseUnit extends ProductPriceBandsState {}

class ProductPriceBandsLoaded extends ProductPriceBandsState {
  final ProductUnitPriceBandsDto data;

  const ProductPriceBandsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class ProductPriceBandsFailure extends ProductPriceBandsState {
  final String error;

  const ProductPriceBandsFailure(this.error);

  @override
  List<Object?> get props => [error];
}
