import 'price_band_source_type.dart';

/// RPC apply result before readiness refresh in the handler.
final class AppliedStorePriceRuleDto {
  const AppliedStorePriceRuleDto({
    required this.productId,
    required this.listPrice,
    required this.floorPrice,
    required this.storePriceRuleId,
    this.productUnitId,
    this.sourceType = PriceBandSourceType.ruleBased,
  });

  final String productId;
  final String? productUnitId;
  final double listPrice;
  final double floorPrice;
  final String storePriceRuleId;
  final PriceBandSourceType sourceType;
}
