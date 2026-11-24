/// Measurement unit models for tenant-level and product-level units (EPIC-04).
library;

/// Tenant-level measurement unit for picker lists (EPIC-04/US-01).
final class TenantMeasurementUnitDto {
  const TenantMeasurementUnitDto({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final String id;
  final String name;
  final bool isActive;

  factory TenantMeasurementUnitDto.fromJson(Map<String, dynamic> row) {
    return TenantMeasurementUnitDto(
      id: row['id'] as String,
      name: row['name'] as String,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

/// Measurement unit associated with a specific product (EPIC-04).
final class ProductUnitDto {
  const ProductUnitDto({
    required this.id,
    required this.name,
    required this.conversionRateToBase,
    required this.isBaseUnit,
    required this.isActive,
  });

  final String id;
  final String name;
  final double conversionRateToBase;
  final bool isBaseUnit;
  final bool isActive;

  factory ProductUnitDto.fromJson(Map<String, dynamic> row) {
    return ProductUnitDto(
      id: row['id'] as String,
      name: row['name'] as String,
      conversionRateToBase: (row['conversion_rate_to_base'] as num).toDouble(),
      isBaseUnit: row['is_base_unit'] as bool,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

/// Collection of product units for a product, including base unit name (EPIC-04).
final class ProductUnitsDto {
  const ProductUnitsDto({
    required this.productId,
    required this.baseUnitName,
    required this.units,
  });

  final String productId;
  final String baseUnitName;
  final List<ProductUnitDto> units;
}

