import 'product_conversion_unit_dto.dart';

/// Units card on Product Control Center (EPIC-01/US-02/FR-02).
final class ProductUnitsCardDto {
  const ProductUnitsCardDto({
    this.baseUnitName,
    this.conversionUnits = const [],
    this.isMissing = false,
    this.missingMessage,
  });

  final String? baseUnitName;
  final List<ProductConversionUnitDto> conversionUnits;
  final bool isMissing;
  final String? missingMessage;
}
