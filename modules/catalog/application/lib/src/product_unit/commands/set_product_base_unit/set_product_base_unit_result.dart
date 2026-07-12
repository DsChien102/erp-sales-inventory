import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';

/// Result after assigning a base unit to a product (EPIC-04/US-01).
final class SetProductBaseUnitResult {
  const SetProductBaseUnitResult({
    required this.productId,
    required this.baseUnitName,
    required this.readinessSummary,
  });

  final String productId;
  final String baseUnitName;
  final ReadinessSummaryDto readinessSummary;
}
