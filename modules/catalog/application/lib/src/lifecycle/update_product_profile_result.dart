import '../control_center/product_profile_summary_dto.dart';
import '../readiness/readiness_summary_dto.dart';

/// Result returned after updating product profile fields.
final class UpdateProductProfileResult {
  const UpdateProductProfileResult({
    required this.productId,
    required this.profile,
    required this.readinessSummary,
    required this.version,
  });

  final String productId;
  final ProductProfileSummaryDto profile;
  final ReadinessSummaryDto readinessSummary;
  final int version;
}
