import 'product_change_category.dart';

/// Semantic product change-history actions (EPIC-07/US-04).
///
/// Wire tokens from RPC/DB are normalized via [tryParse].
enum ProductChangeHistoryAction {
  created,
  profileUpdated,
  imagesUpdated,
  unitAdded,
  unitDeactivated,
  unitReactivated,
  unitDeleted,
  baseUnitSet,
  stockUpdated,
  manualBasePriceSet,
  storePriceRuleApplied,
  priceBandUpdated,
  customFieldValuesUpdated,
  statusChanged,
  deactivated,
  reactivated,
  softDeleted,
  restored
  ;

  ProductChangeCategory get category => switch (this) {
    ProductChangeHistoryAction.created ||
    ProductChangeHistoryAction.profileUpdated => ProductChangeCategory.profile,
    ProductChangeHistoryAction.imagesUpdated => ProductChangeCategory.images,
    ProductChangeHistoryAction.unitAdded ||
    ProductChangeHistoryAction.unitDeactivated ||
    ProductChangeHistoryAction.unitReactivated ||
    ProductChangeHistoryAction.unitDeleted ||
    ProductChangeHistoryAction.baseUnitSet => ProductChangeCategory.units,
    ProductChangeHistoryAction.stockUpdated => ProductChangeCategory.stock,
    ProductChangeHistoryAction.manualBasePriceSet ||
    ProductChangeHistoryAction.storePriceRuleApplied ||
    ProductChangeHistoryAction.priceBandUpdated => ProductChangeCategory.pricing,
    ProductChangeHistoryAction.customFieldValuesUpdated => ProductChangeCategory.customFields,
    ProductChangeHistoryAction.statusChanged ||
    ProductChangeHistoryAction.deactivated ||
    ProductChangeHistoryAction.reactivated => ProductChangeCategory.status,
    ProductChangeHistoryAction.softDeleted ||
    ProductChangeHistoryAction.restored => ProductChangeCategory.lifecycle,
  };

  static ProductChangeHistoryAction? tryParse(String? raw) {
    final token = raw?.trim().toLowerCase() ?? '';
    if (token.isEmpty) {
      return null;
    }
    return switch (token) {
      'created' || 'product_created' => ProductChangeHistoryAction.created,
      'update_product_profile' ||
      'product_profile_updated' ||
      'updated_profile' => ProductChangeHistoryAction.profileUpdated,
      'update_product_images' ||
      'product_images_updated' ||
      'updated_images' => ProductChangeHistoryAction.imagesUpdated,
      'add_product_unit' ||
      'add_product_conversion_unit' => ProductChangeHistoryAction.unitAdded,
      'deactivate_product_unit' ||
      'deactivate_product_conversion_unit' => ProductChangeHistoryAction.unitDeactivated,
      'reactivate_product_unit' ||
      'reactivate_product_conversion_unit' => ProductChangeHistoryAction.unitReactivated,
      'delete_product_conversion_unit' => ProductChangeHistoryAction.unitDeleted,
      'set_product_base_unit' => ProductChangeHistoryAction.baseUnitSet,
      'set_basic_stock_quantity_base' ||
      'set_initial_stock' ||
      'adjust_basic_stock' => ProductChangeHistoryAction.stockUpdated,
      'set_manual_base_price' => ProductChangeHistoryAction.manualBasePriceSet,
      'apply_store_price_rule' => ProductChangeHistoryAction.storePriceRuleApplied,
      'set_product_unit_price_band' ||
      'set_initial_price_band' => ProductChangeHistoryAction.priceBandUpdated,
      'upsert_custom_field_values' ||
      'custom_field_values_updated' => ProductChangeHistoryAction.customFieldValuesUpdated,
      'product_status_changed' => ProductChangeHistoryAction.statusChanged,
      'deactivate_product' => ProductChangeHistoryAction.deactivated,
      'reactivate_product' => ProductChangeHistoryAction.reactivated,
      'product_soft_deleted' => ProductChangeHistoryAction.softDeleted,
      'product_restored' => ProductChangeHistoryAction.restored,
      _ => null,
    };
  }
}
