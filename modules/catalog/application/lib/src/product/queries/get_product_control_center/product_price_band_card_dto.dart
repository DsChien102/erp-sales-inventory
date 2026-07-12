import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/price_band_source_type.dart';

/// Price band card on Product Control Center (EPIC-01/US-02/FR-02).
final class ProductPriceBandCardDto {
  const ProductPriceBandCardDto({
    this.listPrice,
    this.floorPrice,
    this.unitName,
    this.isMissing = false,
    this.missingMessage,
    this.sourceType,
    this.storePriceRuleName,
    this.isCustomOverride = false,
  });

  final double? listPrice;
  final double? floorPrice;
  final String? unitName;
  final bool isMissing;
  final String? missingMessage;
  final PriceBandSourceType? sourceType;
  final String? storePriceRuleName;
  final bool isCustomOverride;
}
