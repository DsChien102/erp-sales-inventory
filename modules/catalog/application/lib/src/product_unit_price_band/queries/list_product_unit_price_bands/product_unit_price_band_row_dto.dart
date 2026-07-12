import 'price_band_source_type.dart';

final class ProductUnitPriceBandRowDto {
  const ProductUnitPriceBandRowDto({
    required this.productUnitId,
    required this.unitName,
    required this.isBaseUnit,
    required this.isActive,
    required this.isMissing,
    this.listPrice,
    this.floorPrice,
    this.sourceType,
    this.storePriceRuleName,
    this.isCustomOverride = false,
  });

  final String productUnitId;
  final String unitName;
  final bool isBaseUnit;
  final bool isActive;
  final double? listPrice;
  final double? floorPrice;
  final bool isMissing;
  final PriceBandSourceType? sourceType;
  final String? storePriceRuleName;
  final bool isCustomOverride;
}
