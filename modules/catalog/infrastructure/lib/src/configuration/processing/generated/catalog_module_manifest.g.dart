// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final catalogModuleManifest = GeneratedModuleManifest(
  name: 'catalog',
  permissions: [
    'catalog.custom_fields.manage',
    'catalog.pricing.manage_store_rule',
    'catalog.product.create',
    'catalog.product.delete',
    'catalog.product.manage_pricing',
    'catalog.product.manage_status',
    'catalog.product.manage_stock',
    'catalog.product.manage_units',
    'catalog.product.update',
    'catalog.product.view',
    'catalog.product.view_detail',
    'catalog.product.view_history',
  ],
  commandTypes: [
    AddProductConversionUnitCommand,
    AdjustBasicStockCommand,
    CreateProductCommand,
    DeactivateProductConversionUnitCommand,
    ReactivateProductConversionUnitCommand,
    RequestProductImageUploadCommand,
    SetInitialPriceBandCommand,
    SetInitialStockCommand,
    SetManualBasePriceCommand,
    SetProductBaseUnitCommand,
  ],
  queryTypes: [
    CheckDuplicateMeasurementUnitNameQuery,
    CheckDuplicateProductCodeQuery,
    GetProductControlCenterQuery,
    GetProductReadinessQuery,
    GetProductStockHistoryQuery,
    ListProductUnitsQuery,
    ListTenantMeasurementUnitsQuery,
    ScanBarcodeQuery,
    SearchProductsQuery,
  ],
);

