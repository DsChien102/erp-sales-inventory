import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';

@ModuleManifest(
  name: 'catalog',
  permissions: [
    CatalogPermissions.view,
    CatalogPermissions.viewDetail,
    CatalogPermissions.create,
    CatalogPermissions.update,
    CatalogPermissions.manageStock,
    CatalogPermissions.manageUnits,
    CatalogPermissions.managePricing,
    CatalogPermissions.manageStatus,
    CatalogPermissions.delete,
    CatalogPermissions.viewHistory,
    CatalogPermissions.manageCustomFields,
    CatalogPermissions.manageStorePriceRule,
  ],
)
final class CatalogModuleDefinition {}
