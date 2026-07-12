import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_readiness_permission_context.dart';

/// Resolves catalog readiness permission flags for assemblers/handlers.
abstract final class ProductReadinessPermissionResolver {
  static Future<ProductReadinessPermissionContext> resolve(
    IPermissionChecker permissionChecker, {
    bool canViewHistory = false,
  }) async {
    return ProductReadinessPermissionContext(
      canManageUnits: await _can(permissionChecker, CatalogPermissions.manageUnits),
      canManageStock: await _can(permissionChecker, CatalogPermissions.manageStock),
      canManagePricing: await _can(permissionChecker, CatalogPermissions.managePricing),
      canUpdateProduct: await _can(permissionChecker, CatalogPermissions.update),
      canCreateProduct: await _can(permissionChecker, CatalogPermissions.create),
      canViewDetail: await _can(permissionChecker, CatalogPermissions.viewDetail),
    );
  }

  static Future<bool> canViewHistory(IPermissionChecker permissionChecker) {
    return _can(permissionChecker, CatalogPermissions.viewHistory);
  }

  static Future<bool> _can(
    IPermissionChecker permissionChecker,
    String permissionCode,
  ) async {
    try {
      await permissionChecker.require(permissionCode);
      return true;
    } on ApplicationException {
      return false;
    }
  }
}
