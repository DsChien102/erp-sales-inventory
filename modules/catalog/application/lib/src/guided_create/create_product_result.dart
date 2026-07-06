import '../readiness/readiness_summary_dto.dart';

final class CreateProductResult {
  const CreateProductResult({
    required this.productId,
    required this.readinessSummary,
  });

  final String productId;
  final ReadinessSummaryDto readinessSummary;
}
