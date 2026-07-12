import 'package:vet45_catalog_domain/domain.dart';

import 'product_unit_dto.dart';
import 'product_units_dto.dart';

ProductUnitSet productUnitSetFromDto(ProductUnitsDto dto) {
  return ProductUnitSet(
    productId: dto.productId,
    units: dto.units.map((unit) => productUnitFromDto(dto.productId, unit)),
  );
}

ProductUnit productUnitFromDto(String productId, ProductUnitDto dto) {
  return ProductUnit(
    id: dto.id,
    productId: productId,
    name: dto.name,
    conversionRateToBase: dto.conversionRateToBase,
    isBaseUnit: dto.isBaseUnit,
    isActive: dto.isActive,
  );
}
