import '../../readiness/readiness_summary_dto.dart';
import 'price_band_source_type.dart';

/// Stub result for slice #11 — manual price band override.
final class SetProductUnitPriceBandResult {
  const SetProductUnitPriceBandResult({
    required this.productId,
    required this.listPrice,
    required this.floorPrice,
    required this.sourceType,
    required this.readinessSummary,
    this.productUnitId,
    this.storePriceRuleId,
  });

  final String productId;
  final String? productUnitId;
  final double listPrice;
  final double floorPrice;
  final PriceBandSourceType sourceType;
  final String? storePriceRuleId;
  final ReadinessSummaryDto readinessSummary;
}
