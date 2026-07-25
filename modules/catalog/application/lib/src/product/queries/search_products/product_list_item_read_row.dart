import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/product/queries/list_custom_field_filter_options/custom_field_list_value_dto.dart';

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
    required this.facts,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.baseUnit,
    this.stockQuantity,
    this.customFieldValues = const [],
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? tradeName;
  final String? sku;
  final String? barcode;
  final String? primaryImageUrl;
  final ProductBusinessStatus businessStatus;
  final ProductReadinessFacts facts;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final String? baseUnit;
  final int? stockQuantity;
  final List<CustomFieldListValueDto> customFieldValues;
  final DateTime updatedAt;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;
}
