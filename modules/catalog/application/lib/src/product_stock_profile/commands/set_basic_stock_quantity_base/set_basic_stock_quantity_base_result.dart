import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';

final class SetBasicStockQuantityBaseResult {
  const SetBasicStockQuantityBaseResult({
    required this.productId,
    required this.quantity,
    required this.readinessSummary,
    this.unitName,
  });

  final String productId;
  final int quantity;
  final String? unitName;
  final ReadinessSummaryDto readinessSummary;
}
