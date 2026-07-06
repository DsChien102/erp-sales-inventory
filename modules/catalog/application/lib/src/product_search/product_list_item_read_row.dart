import 'package:vet45_catalog_domain/domain.dart';

/// Intermediate row mapped from catalog search / barcode RPC.
final class ProductListItemReadRow {
  const ProductListItemReadRow({
    required this.id,
    required this.name,
    this.tradeName,
    this.sku,
    this.barcode,
    this.primaryImageUrl,
    required this.businessStatus,
    this.isSoftDeleted = false,
    required this.facts,
    this.listPrice,
    this.floorPrice,
    this.baseUnit,
    this.stockQuantity,
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
  final ProductReadinessFacts facts;
  final double? listPrice;
  final double? floorPrice;
  final String? baseUnit;
  final int? stockQuantity;
  final DateTime updatedAt;
}
