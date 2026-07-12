import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

abstract final class ProductPriceBandRpcMapper {
  static Map<String, dynamic> setProductUnitPriceBandParams({
    required String tenantId,
    required String productId,
    required String productUnitId,
    required double listPrice,
    required double floorPrice,
    required PriceBandSourceType sourceType,
    String? storePriceRuleId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      'p_product_unit_id': productUnitId,
      'p_list_price': listPrice,
      'p_floor_price': floorPrice,
      'p_source_type': sourceTypeToRpc(sourceType),
      'p_store_price_rule_id': storePriceRuleId,
    };
  }

  static Map<String, dynamic> listProductUnitPriceBandsParams({
    required String tenantId,
    required String productId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
    };
  }

  static Map<String, dynamic> getPriceBandSnapshotParams({
    required String tenantId,
    required List<ProductPriceBandSnapshotRequest> items,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_items': items
          .map(
            (item) => <String, dynamic>{
              'product_id': item.productId,
              'product_unit_id': item.productUnitId,
            },
          )
          .toList(growable: false),
    };
  }

  static ProductPriceBandSnapshotDto snapshotFromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      return const ProductPriceBandSnapshotDto(items: []);
    }

    return ProductPriceBandSnapshotDto(
      items: rawItems
          .whereType<Map>()
          .map((item) => snapshotItemFromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  static ProductPriceBandSnapshotItemDto snapshotItemFromJson(
    Map<String, dynamic> item,
  ) {
    return ProductPriceBandSnapshotItemDto(
      productId: item['product_id'] as String,
      productUnitId: item['product_unit_id'] as String,
      unitName: item['unit_name'] as String? ?? '',
      currency: item['currency'] as String? ?? 'VND',
      listPrice: (item['list_price'] as num?)?.toDouble(),
      listPriceMissing: item['list_price_missing'] as bool? ?? true,
      floorPrice: (item['floor_price'] as num?)?.toDouble(),
      floorPriceMissing: item['floor_price_missing'] as bool? ?? true,
      floorPriceHidden: item['floor_price_hidden'] as bool? ?? false,
      isUnitActive: item['is_unit_active'] as bool? ?? false,
      productBusinessStatus: _productStatusFromRpc(
        item['product_business_status'] as String?,
      ),
      capturedAt: DateTime.utc(1970),
    );
  }

  static ProductBusinessStatus _productStatusFromRpc(String? value) {
    return switch (value) {
      'inactive' => ProductBusinessStatus.inactive,
      'soft_deleted' => ProductBusinessStatus.softDeleted,
      _ => ProductBusinessStatus.active,
    };
  }

  static ProductUnitPriceBandsDto bandsFromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      throw ArgumentError('Price band list returned no rows.');
    }
    final first = rows.first;
    final productId = first['product_id'] as String;
    final baseUnitName = first['base_unit_name'] as String? ?? '';
    final currency = first['currency'] as String? ?? 'VND';
    final basePrice = _readOptionalPrice(first, 'base_price', 'base_price_amount');

    return ProductUnitPriceBandsDto(
      productId: productId,
      baseUnitName: baseUnitName,
      currency: currency,
      basePrice: basePrice,
      rows: rows.map(rowFromListRpc).toList(growable: false),
    );
  }

  static double? _readOptionalPrice(
    Map<String, dynamic> row,
    String key,
    String legacyKey,
  ) {
    return (row[key] as num?)?.toDouble() ?? (row[legacyKey] as num?)?.toDouble();
  }

  static ProductUnitPriceBandRowDto rowFromListRpc(Map<String, dynamic> row) {
    final listPrice = _readOptionalPrice(row, 'list_price', 'list_price_amount');
    final floorPrice = _readOptionalPrice(row, 'floor_price', 'floor_price_amount');
    final isMissing = listPrice == null || floorPrice == null;

    return ProductUnitPriceBandRowDto(
      productUnitId: row['product_unit_id'] as String,
      unitName: row['unit_name'] as String,
      isBaseUnit: row['is_base_unit'] as bool? ?? false,
      isActive: row['is_active'] as bool? ?? true,
      listPrice: listPrice,
      floorPrice: floorPrice,
      isMissing: isMissing,
      sourceType: sourceTypeFromRpc(row['source_type'] as String?),
      storePriceRuleName: row['store_price_rule_name'] as String?,
      isCustomOverride: row['is_custom_override'] as bool? ?? false,
    );
  }

  static String sourceTypeToRpc(PriceBandSourceType sourceType) {
    return switch (sourceType) {
      PriceBandSourceType.ruleBased => 'ruleBased',
      PriceBandSourceType.manual => 'manual',
    };
  }

  static PriceBandSourceType? sourceTypeFromRpc(String? value) {
    return switch (value) {
      'ruleBased' => PriceBandSourceType.ruleBased,
      'manual' => PriceBandSourceType.manual,
      _ => null,
    };
  }
}
