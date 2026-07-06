/// RBAC permission codes for the catalog module (TH-02).
abstract final class CatalogPermissions {
  static const view = 'catalog.product.view';
  static const viewDetail = 'catalog.product.view_detail';
  static const create = 'catalog.product.create';
  static const update = 'catalog.product.update';
  static const manageStock = 'catalog.product.manage_stock';
  static const manageUnits = 'catalog.product.manage_units';
  static const managePricing = 'catalog.product.manage_pricing';
  static const manageStatus = 'catalog.product.manage_status';
  static const delete = 'catalog.product.delete';
  static const viewHistory = 'catalog.product.view_history';
  static const manageCustomFields = 'catalog.custom_fields.manage';
  static const manageStorePriceRule = 'catalog.pricing.manage_store_rule';
}
