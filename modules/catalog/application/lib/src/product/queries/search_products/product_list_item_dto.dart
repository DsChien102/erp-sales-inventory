import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/product/queries/list_custom_field_filter_options/custom_field_list_value_dto.dart';

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
    required this.readinessSummary,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.baseUnit,
    this.stockQuantity,
    this.stockLabel,
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
  final ReadinessSummaryDto readinessSummary;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final int? listAfterVat;
  final int? floorAfterVat;
  final String? baseUnit;
  final int? stockQuantity;
  final String? stockLabel;
  final List<CustomFieldListValueDto> customFieldValues;
  final DateTime updatedAt;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;
}
