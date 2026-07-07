import '../readiness/readiness_summary_dto.dart';
import 'product_image_dto.dart';

/// Result returned after replacing a product image gallery.
final class UpdateProductImagesResult {
  const UpdateProductImagesResult({
    required this.productId,
    required this.images,
    this.primaryImageUrl,
    required this.readinessSummary,
    required this.version,
  });

  final String productId;
  final List<ProductImageDto> images;
  final String? primaryImageUrl;
  final ReadinessSummaryDto readinessSummary;
  final int version;
}
