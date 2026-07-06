import '../../readiness/readiness_summary_dto.dart';
import 'price_band_source_type.dart';

final class ApplyStorePriceRuleResult {
  const ApplyStorePriceRuleResult({
    required this.productId,
    required this.listPrice,
    required this.floorPrice,
    required this.storePriceRuleId,
    required this.sourceType,
    required this.readinessSummary,
    this.productUnitId,
  });

  final String productId;
  final String? productUnitId;
  final double listPrice;
  final double floorPrice;
  final String storePriceRuleId;
  final PriceBandSourceType sourceType;
  final ReadinessSummaryDto readinessSummary;
}
