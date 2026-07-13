import 'package:vet45_catalog_application/application.dart';

abstract final class StorePriceRuleRpcMapper {
  static Map<String, dynamic> getStorePriceRuleParams({
    required String tenantId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
    };
  }

  static Map<String, dynamic> setStorePriceRuleParams({
    required String tenantId,
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    required StorePriceRuleStatus status,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_name': name,
      'p_list_markup_ratio': listMarkupRatio,
      'p_floor_markup_ratio': floorMarkupRatio,
      'p_status': _statusToRpc(status),
    };
  }

  static Map<String, dynamic> suggestProductUnitPriceParams({
    required String tenantId,
    required String productId,
    String? productUnitId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      'p_product_unit_id': productUnitId,
    };
  }

  static Map<String, dynamic> applyStorePriceRuleParams({
    required ApplyStorePriceRuleCommand command,
  }) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_product_id': command.productId,
      'p_product_unit_id': command.productUnitId,
      'p_store_price_rule_id': command.storePriceRuleId,
      'p_confirm_overwrite': command.confirmOverwrite,
      'p_base_price_version': command.basePriceVersion,
    };
  }

  static StorePriceRuleDto? ruleFromRow(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null || id.isEmpty) {
      return null;
    }
    return StorePriceRuleDto(
      id: id,
      tenantId: row['tenant_id'] as String,
      name: row['name'] as String,
      status: _statusFromRpc(row['status'] as String?),
      calculationType: StorePriceCalculationType.markup,
      listMarkupRatio: (row['list_markup_ratio'] as num).toDouble(),
      floorMarkupRatio: (row['floor_markup_ratio'] as num).toDouble(),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String),
    );
  }

  static ProductUnitPriceSuggestionDto suggestionFromRow(Map<String, dynamic> row) {
    return ProductUnitPriceSuggestionDto(
      productId: row['product_id'] as String,
      productUnitId: row['product_unit_id'] as String?,
      unitName: row['unit_name'] as String?,
      basePrice: (row['base_price'] as num?)?.toDouble() ?? 0,
      currency: row['currency'] as String? ?? 'VND',
      suggestedListBeforeVat:
          (row['suggested_list_price_before_vat'] as num?)?.round() ??
              (row['suggested_list_price'] as num?)?.round(),
      suggestedFloorBeforeVat:
          (row['suggested_floor_price_before_vat'] as num?)?.round() ??
              (row['suggested_floor_price'] as num?)?.round(),
      storePriceRuleId: row['store_price_rule_id'] as String?,
      storePriceRuleName: row['store_price_rule_name'] as String?,
      basePriceVersion: (row['base_price_version'] as num?)?.toInt(),
      canSuggest: row['can_suggest'] as bool? ?? false,
      unavailableReason: row['unavailable_reason'] as String?,
    );
  }

  static AppliedStorePriceRuleDto appliedFromRow(Map<String, dynamic> row) {
    return AppliedStorePriceRuleDto(
      productId: row['product_id'] as String,
      productUnitId: row['product_unit_id'] as String?,
      listBeforeVat: ((row['list_price_before_vat'] as num?) ??
              (row['list_price'] as num))
          .round(),
      floorBeforeVat: ((row['floor_price_before_vat'] as num?) ??
              (row['floor_price'] as num))
          .round(),
      storePriceRuleId: row['store_price_rule_id'] as String,
      sourceType: PriceBandSourceType.ruleBased,
    );
  }

  static PriceBandSourceType? sourceTypeFromRpc(String? value) {
    return switch (value) {
      'ruleBased' => PriceBandSourceType.ruleBased,
      'manual' => PriceBandSourceType.manual,
      _ => null,
    };
  }

  static String _statusToRpc(StorePriceRuleStatus status) {
    return switch (status) {
      StorePriceRuleStatus.active => 'active',
      StorePriceRuleStatus.inactive => 'inactive',
    };
  }

  static StorePriceRuleStatus _statusFromRpc(String? value) {
    return switch (value) {
      'inactive' => StorePriceRuleStatus.inactive,
      _ => StorePriceRuleStatus.active,
    };
  }
}
