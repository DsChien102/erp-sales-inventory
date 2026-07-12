import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';

final class CreateGuidedProductResult {
  const CreateGuidedProductResult({
    required this.productId,
    required this.readinessSummary,
  });

  final String productId;
  final ReadinessSummaryDto readinessSummary;
}
