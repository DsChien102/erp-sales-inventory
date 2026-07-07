// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final catalogAccessMetadataRegistry = AccessMetadataRegistry({
  AddProductConversionUnitCommand: AccessMetadata(
    permission: 'catalog.product.manage_units',
    requiresTenant: true,
  ),
  AdjustBasicStockCommand: AccessMetadata(
    permission: 'catalog.product.manage_stock',
    requiresTenant: true,
  ),
  ApplyStorePriceRuleCommand: AccessMetadata(
    permission: 'catalog.product.manage_pricing',
    requiresTenant: true,
  ),
  CheckDuplicateMeasurementUnitNameQuery: AccessMetadata(
    permission: 'catalog.product.manage_units',
    requiresTenant: true,
  ),
  CheckDuplicateProductCodeQuery: AccessMetadata(
    permission: 'catalog.product.create',
    requiresTenant: true,
  ),
  CheckProductDeletionEligibilityQuery: AccessMetadata(
    permission: 'catalog.product.delete',
    requiresTenant: true,
  ),
  CreateProductCommand: AccessMetadata(
    permission: 'catalog.product.create',
    requiresTenant: true,
  ),
  DeactivateProductCommand: AccessMetadata(
    permission: 'catalog.product.manage_status',
    requiresTenant: true,
  ),
  DeactivateProductConversionUnitCommand: AccessMetadata(
    permission: 'catalog.product.manage_units',
    requiresTenant: true,
  ),
  DeleteProductCommand: AccessMetadata(
    permission: 'catalog.product.delete',
    requiresTenant: true,
  ),
  GetProductControlCenterQuery: AccessMetadata(
    permission: 'catalog.product.view_detail',
    requiresTenant: true,
  ),
  GetProductReadinessQuery: AccessMetadata(
    permission: 'catalog.product.view_detail',
    requiresTenant: true,
  ),
  GetProductStockHistoryQuery: AccessMetadata(
    permission: 'catalog.product.view_history',
    requiresTenant: true,
  ),
  GetStorePriceRuleQuery: AccessMetadata(
    permission: 'catalog.pricing.manage_store_rule',
    requiresTenant: true,
  ),
  ListProductUnitPriceBandsQuery: AccessMetadata(
    permission: 'catalog.product.view_detail',
    requiresTenant: true,
  ),
  ListProductUnitsQuery: AccessMetadata(
    permission: 'catalog.product.manage_units',
    requiresTenant: true,
  ),
  ListTenantMeasurementUnitsQuery: AccessMetadata(
    permission: 'catalog.product.manage_units',
    requiresTenant: true,
  ),
  ReactivateProductCommand: AccessMetadata(
    permission: 'catalog.product.manage_status',
    requiresTenant: true,
  ),
  ReactivateProductConversionUnitCommand: AccessMetadata(
    permission: 'catalog.product.manage_units',
    requiresTenant: true,
  ),
  RequestProductImageUploadCommand: AccessMetadata(
    permission: 'catalog.product.create',
    requiresTenant: true,
  ),
  RequestProductMaintenanceImageUploadCommand: AccessMetadata(
    permission: 'catalog.product.update',
    requiresTenant: true,
  ),
  RestoreProductCommand: AccessMetadata(
    permission: 'catalog.product.delete',
    requiresTenant: true,
  ),
  ScanBarcodeQuery: AccessMetadata(
    permission: 'catalog.product.view',
    requiresTenant: true,
  ),
  SearchProductsQuery: AccessMetadata(
    permission: 'catalog.product.view',
    requiresTenant: true,
  ),
  SetInitialPriceBandCommand: AccessMetadata(
    permission: 'catalog.product.manage_pricing',
    requiresTenant: true,
  ),
  SetInitialStockCommand: AccessMetadata(
    permission: 'catalog.product.manage_stock',
    requiresTenant: true,
  ),
  SetManualBasePriceCommand: AccessMetadata(
    permission: 'catalog.product.manage_pricing',
    requiresTenant: true,
  ),
  SetProductBaseUnitCommand: AccessMetadata(
    permission: 'catalog.product.manage_units',
    requiresTenant: true,
  ),
  SetProductUnitPriceBandCommand: AccessMetadata(
    permission: 'catalog.product.manage_pricing',
    requiresTenant: true,
  ),
  SetStorePriceRuleCommand: AccessMetadata(
    permission: 'catalog.pricing.manage_store_rule',
    requiresTenant: true,
  ),
  SuggestProductUnitPriceQuery: AccessMetadata(
    permission: 'catalog.product.manage_pricing',
    requiresTenant: true,
  ),
  UpdateProductImagesCommand: AccessMetadata(
    permission: 'catalog.product.update',
    requiresTenant: true,
  ),
  UpdateProductProfileCommand: AccessMetadata(
    permission: 'catalog.product.update',
    requiresTenant: true,
  ),
});

