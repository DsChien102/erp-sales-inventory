import 'package:vet45_catalog_application/src/product/queries/get_product_control_center/product_profile_summary_dto.dart';
import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';

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
