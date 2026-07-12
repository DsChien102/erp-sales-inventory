import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';

final class AdjustBasicStockResult {
  const AdjustBasicStockResult({
    required this.productId,
    required this.previousQuantity,
    required this.newQuantity,
    required this.readinessSummary,
    this.unitName,
  });

  final String productId;
  final int previousQuantity;
  final int newQuantity;
  final String? unitName;
  final ReadinessSummaryDto readinessSummary;
}
