import '../readiness/readiness_summary_dto.dart';

final class SetManualBasePriceResult {
  const SetManualBasePriceResult({
    required this.productId,
    required this.basePrice,
    required this.currency,
    required this.readinessSummary,
    this.unitName,
  });

  final String productId;
  final double basePrice;
  final String currency;
  final String? unitName;
  final ReadinessSummaryDto readinessSummary;
}
