import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'package:vet45_catalog_application/src/product/queries/list_custom_field_filter_options/custom_field_list_value_dto.dart';
import 'product_list_item_dto.dart';
import 'product_list_item_read_row.dart';

/// Maps search RPC rows to [ProductListItemDto] with computed readiness.
abstract final class ProductListItemAssembler {
  static ProductListItemDto toDto(ProductListItemReadRow row) {
    final readiness = ProductReadinessEvaluator.compute(row.facts);
    final stockLabel = row.stockQuantity?.toString();

    return ProductListItemDto(
      id: row.id,
      name: row.name,
      tradeName: row.tradeName,
      sku: row.sku,
      barcode: row.barcode,
      primaryImageUrl: row.primaryImageUrl,
      businessStatus: row.businessStatus,
      isSoftDeleted: row.isSoftDeleted,
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
      listPrice: row.listPrice,
      floorPrice: row.floorPrice,
      baseUnit: row.baseUnit,
      stockQuantity: row.stockQuantity,
      stockLabel: stockLabel,
      customFieldValues: row.customFieldValues,
      updatedAt: row.updatedAt,
    );
  }
}
