import 'package:vet45_catalog_domain/domain.dart';

/// Profile summary for Product Control Center (EPIC-01/US-02/FR-01).
final class ProductProfileSummaryDto {
  const ProductProfileSummaryDto({
    required this.productId,
    required this.name,
    this.tradeName,
    this.sku,
    this.barcode,
    required this.businessStatus,
    this.isSoftDeleted = false,
    this.primaryImageUrl,
    this.images = const [],
    this.description,
    this.note,
  });

  final String productId;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final ProductStatus businessStatus;
  final bool isSoftDeleted;
  final String? primaryImageUrl;
  final List<String> images;
  final String? description;
  final String? note;
}
