import 'package:vet45_catalog_application/application.dart';

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

  static ProductUnitPriceBandsDto bandsFromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      throw ArgumentError('Price band list returned no rows.');
    }
    final first = rows.first;
    final productId = first['product_id'] as String;
    final baseUnitName = first['base_unit_name'] as String? ?? '';
    final currency = first['currency'] as String? ?? 'VND';

    return ProductUnitPriceBandsDto(
      productId: productId,
      baseUnitName: baseUnitName,
      currency: currency,
      rows: rows.map(rowFromListRpc).toList(growable: false),
    );
  }

  static ProductUnitPriceBandRowDto rowFromListRpc(Map<String, dynamic> row) {
    final listPrice = (row['list_price'] as num?)?.toDouble();
    final floorPrice = (row['floor_price'] as num?)?.toDouble();
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
