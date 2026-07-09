import 'package:equatable/equatable.dart';
import 'package:vet45_catalog_application/application.dart';

enum ProductMeasurementUnitsStatus { initial, loading, success, failure }

final class ProductMeasurementUnitsState extends Equatable {
  const ProductMeasurementUnitsState({
    this.status = ProductMeasurementUnitsStatus.initial,
    this.tenantUnits = const [],
    this.saveStatus = ProductMeasurementUnitsStatus.initial,
    this.errorMessage,
    this.productId = '',
    this.baseUnitName,
    this.productUnits,
    this.unitMutationStatus = ProductMeasurementUnitsStatus.initial,
    this.deleteBlockedUnitId,
  });

  final ProductMeasurementUnitsStatus status;
  final List<TenantMeasurementUnitDto> tenantUnits;
  final ProductMeasurementUnitsStatus saveStatus;
  final String? errorMessage;
  final String productId;
  final String? baseUnitName;
  final ProductUnitsDto? productUnits;
  final ProductMeasurementUnitsStatus unitMutationStatus;
  final String? deleteBlockedUnitId;

  List<ProductUnitDto> get conversionUnits => 
      productUnits?.units.where((u) => !u.isBaseUnit).toList() ?? [];

  ProductMeasurementUnitsState copyWith({
    ProductMeasurementUnitsStatus? status,
    List<TenantMeasurementUnitDto>? tenantUnits,
    ProductMeasurementUnitsStatus? saveStatus,
    String? errorMessage,
    String? productId,
    String? baseUnitName,
    ProductUnitsDto? productUnits,
    ProductMeasurementUnitsStatus? unitMutationStatus,
    String? deleteBlockedUnitId,
    bool clearDeleteBlockedUnitId = false,
  }) {
    return ProductMeasurementUnitsState(
      status: status ?? this.status,
      tenantUnits: tenantUnits ?? this.tenantUnits,
      saveStatus: saveStatus ?? this.saveStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      productId: productId ?? this.productId,
      baseUnitName: baseUnitName ?? this.baseUnitName,
      productUnits: productUnits ?? this.productUnits,
      unitMutationStatus: unitMutationStatus ?? this.unitMutationStatus,
      deleteBlockedUnitId: clearDeleteBlockedUnitId
          ? null
          : (deleteBlockedUnitId ?? this.deleteBlockedUnitId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        tenantUnits,
        saveStatus,
        errorMessage,
        productId,
        baseUnitName,
        productUnits,
        unitMutationStatus,
        deleteBlockedUnitId,
      ];
}
