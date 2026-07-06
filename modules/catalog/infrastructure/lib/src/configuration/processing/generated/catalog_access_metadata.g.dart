// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final catalogAccessMetadataRegistry = AccessMetadataRegistry({
  CheckDuplicateMeasurementUnitNameQuery: AccessMetadata(
    permission: 'catalog.product.manage_units',
    requiresTenant: true,
  ),
  CheckDuplicateProductCodeQuery: AccessMetadata(
    permission: 'catalog.product.create',
    requiresTenant: true,
  ),
  CreateProductCommand: AccessMetadata(
    permission: 'catalog.product.create',
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
  ListTenantMeasurementUnitsQuery: AccessMetadata(
    permission: 'catalog.product.manage_units',
    requiresTenant: true,
  ),
  RequestProductImageUploadCommand: AccessMetadata(
    permission: 'catalog.product.create',
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
});
