import 'package:vet45_catalog_domain/domain.dart';

import 'price_band_source_type.dart';

final class ProductUnitPriceBandRowDto {
  const ProductUnitPriceBandRowDto({
    required this.productUnitId,
    required this.unitName,
    required this.isBaseUnit,
    required this.isActive,
    required this.isMissing,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.effectiveFrom,
    this.effectiveTo,
    this.status,
    this.sourceType,
    this.storePriceRuleName,
    this.isCustomOverride = false,
  });

  final String productUnitId;
  final String unitName;
  final bool isBaseUnit;
  final bool isActive;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus? status;
  final bool isMissing;
  final PriceBandSourceType? sourceType;
  final String? storePriceRuleName;
  final bool isCustomOverride;
}
