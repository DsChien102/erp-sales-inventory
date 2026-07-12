import 'package:vet45_catalog_domain/domain.dart';

/// Resolved permission flags for contextual action `enabled` state.
final class ProductReadinessPermissionContext {
  const ProductReadinessPermissionContext({
    required this.canManageUnits,
    required this.canManageStock,
    required this.canManagePricing,
    required this.canUpdateProduct,
    required this.canCreateProduct,
    required this.canViewDetail,
  });

  final bool canManageUnits;
  final bool canManageStock;
  final bool canManagePricing;
  final bool canUpdateProduct;
  final bool canCreateProduct;
  final bool canViewDetail;

  bool can(String? permissionCode) {
    if (permissionCode == null) {
      return true;
    }
    return switch (permissionCode) {
      CatalogPermissions.manageUnits => canManageUnits,
      CatalogPermissions.manageStock => canManageStock,
      CatalogPermissions.managePricing => canManagePricing,
      CatalogPermissions.update => canUpdateProduct,
      CatalogPermissions.create => canCreateProduct,
      CatalogPermissions.viewDetail => canViewDetail,
      _ => false,
    };
  }
}
