import '../readiness/readiness_summary_dto.dart';

final class SetInitialStockResult {
  const SetInitialStockResult({
    required this.productId,
    required this.quantity,
    required this.readinessSummary,
    this.unitName,
  });

  final String productId;
  final double quantity;
  final String? unitName;
  final ReadinessSummaryDto readinessSummary;
}
