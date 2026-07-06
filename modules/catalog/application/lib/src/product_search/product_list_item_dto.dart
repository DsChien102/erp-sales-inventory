import '../readiness/readiness_summary_dto.dart';
import 'package:vet45_catalog_domain/domain.dart';

/// List row DTO for product search and barcode scan (EPIC-01/US-01).
final class ProductListItemDto {
  const ProductListItemDto({
    required this.id,
    required this.name,
    this.tradeName,
    this.sku,
    this.barcode,
    this.primaryImageUrl,
    required this.businessStatus,
    this.isSoftDeleted = false,
    required this.readinessSummary,
    this.listPrice,
    this.floorPrice,
    this.baseUnit,
    this.stockQuantity,
    this.stockLabel,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final String? primaryImageUrl;
  final ProductStatus businessStatus;
  final bool isSoftDeleted;
  final ReadinessSummaryDto readinessSummary;
  final double? listPrice;
  final double? floorPrice;
  final String? baseUnit;
  final int? stockQuantity;
  final String? stockLabel;
  final DateTime updatedAt;
}
