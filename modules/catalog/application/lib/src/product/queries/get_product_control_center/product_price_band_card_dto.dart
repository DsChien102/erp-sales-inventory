import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/price_band_source_type.dart';

/// Price band card on Product Control Center (EPIC-01/US-02/FR-02).
final class ProductPriceBandCardDto {
  const ProductPriceBandCardDto({
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.effectiveFrom,
    this.effectiveTo,
    this.status,
    this.unitName,
    this.isMissing = false,
    this.missingMessage,
    this.sourceType,
    this.storePriceRuleName,
    this.isCustomOverride = false,
  });

  final int? listBeforeVat;
  final int? floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus? status;
  final String? unitName;
  final bool isMissing;
  final String? missingMessage;
  final PriceBandSourceType? sourceType;
  final String? storePriceRuleName;
  final bool isCustomOverride;
}
