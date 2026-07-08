import 'product_change_category.dart';

/// Maps persisted change-history action codes to business categories.
abstract final class ProductChangeCategoryMapper {
  static ProductChangeCategory fromAction(String action) {
    final normalized = action.trim().toLowerCase();
    return switch (normalized) {
      'created' ||
      'update_product_profile' ||
      'product_profile_updated' =>
        ProductChangeCategory.profile,
      'update_product_images' || 'product_images_updated' =>
        ProductChangeCategory.images,
      'add_product_unit' ||
      'deactivate_product_unit' ||
      'reactivate_product_unit' ||
      'set_product_base_unit' =>
        ProductChangeCategory.units,
      'set_initial_stock' || 'adjust_basic_stock' => ProductChangeCategory.stock,
      'set_manual_base_price' ||
      'apply_store_price_rule' ||
      'set_product_unit_price_band' ||
      'set_initial_price_band' =>
        ProductChangeCategory.pricing,
      'upsert_custom_field_values' ||
      'custom_field_values_updated' =>
        ProductChangeCategory.customFields,
      'product_status_changed' ||
      'deactivate_product' ||
      'reactivate_product' =>
        ProductChangeCategory.status,
      'product_soft_deleted' || 'product_restored' => ProductChangeCategory.lifecycle,
      _ => ProductChangeCategory.other,
    };
  }
}
