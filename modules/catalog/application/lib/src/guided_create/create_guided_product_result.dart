import '../readiness/readiness_summary_dto.dart';

final class CreateGuidedProductResult {
  const CreateGuidedProductResult({
    required this.productId,
    required this.readinessSummary,
  });

  final String productId;
  final ReadinessSummaryDto readinessSummary;
}
