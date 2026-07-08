import '../readiness/readiness_summary_dto.dart';

final class AdjustBasicStockResult {
  const AdjustBasicStockResult({
    required this.productId,
    required this.previousQuantity,
    required this.newQuantity,
    required this.readinessSummary,
    this.unitName,
  });

  final String productId;
  final double previousQuantity;
  final double newQuantity;
  final String? unitName;
  final ReadinessSummaryDto readinessSummary;
}
