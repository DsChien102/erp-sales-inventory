import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/price_band_source_type.dart';

/// RPC apply result before readiness refresh in the handler.
final class AppliedStorePriceRuleDto {
  const AppliedStorePriceRuleDto({
    required this.productId,
    required this.listBeforeVat,
    required this.floorBeforeVat,
    required this.storePriceRuleId,
    this.productUnitId,
    this.listAfterVat,
    this.floorAfterVat,
    this.effectiveFrom,
    this.effectiveTo,
    this.status,
    this.sourceType = PriceBandSourceType.ruleBased,
  });

  final String productId;
  final String? productUnitId;
  final int listBeforeVat;
  final int floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus? status;
  final String storePriceRuleId;
  final PriceBandSourceType sourceType;
}
