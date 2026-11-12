import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:erp/features/catalog/data/models/catalog_enums.dart';
import 'package:erp/features/catalog/data/models/custom_field_config.dart';
import 'package:erp/features/catalog/data/models/custom_field_filter_option.dart';
import 'package:erp/features/catalog/data/models/measurement_unit.dart';
import 'package:erp/features/catalog/data/models/price_band.dart';
import 'package:erp/features/catalog/data/models/product_change_history.dart';
import 'package:erp/features/catalog/data/models/product_control_center.dart';
import 'package:erp/features/catalog/data/models/product_custom_field_values.dart';
import 'package:erp/features/catalog/data/models/product_inputs.dart';
import 'package:erp/features/catalog/data/models/product_readiness.dart';
import 'package:erp/features/catalog/data/models/product_results.dart';
import 'package:erp/features/catalog/data/models/product_search.dart';
import 'package:erp/features/catalog/data/models/sellable_product.dart';
import 'package:erp/features/catalog/data/models/store_price_rule.dart';
import 'package:erp/features/catalog/logic/catalog_permissions.dart';
import 'package:erp/features/catalog/logic/product_readiness.dart';
import 'package:erp/features/catalog/logic/store_price_suggestion.dart';

import 'fake_catalog_custom_field_store.dart';
import 'fake_catalog_product_builder.dart';
import 'fake_catalog_scenario.dart';
import 'fake_product_readiness_builder.dart';

class FakeTenantUnit {
  FakeTenantUnit({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final String id;
  final String name;
  bool isActive;
}

class FakeProductUnit {
  FakeProductUnit({
    required this.id,
    required this.productId,
    required this.name,
    required this.conversionRateToBase,
    required this.isBaseUnit,
    required this.isActive,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.priceBandSourceType,
    this.isCustomOverride = false,
    this.hasConversionRate = true,
  }) : hasTransactionUsage = false,
       listMarkupRatio = null,
       floorMarkupRatio = null,
       floorAfterVat = null;

  final String id;
  final String productId;
  final String name;
  final double conversionRateToBase;
  final bool isBaseUnit;
  bool isActive;
  int? listBeforeVat;
  int? floorBeforeVat;
  int? listAfterVat;
  int? floorAfterVat;
  PriceBandSourceType? priceBandSourceType;
  double? listMarkupRatio;
  double? floorMarkupRatio;
  String? storePriceRuleId;
  String? storePriceRuleName;
  bool isCustomOverride;
  final bool hasConversionRate;
  bool hasTransactionUsage;

  bool get hasPriceBandAmounts => listBeforeVat != null && listAfterVat != null;
}

class FakeStockMovement {
  const FakeStockMovement({
    required this.id,
    required this.occurredAt,
    required this.actorDisplayName,
    required this.movementType,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.delta,
    this.reason,
  });

  final String id;
  final DateTime occurredAt;
  final String actorDisplayName;
  final String movementType;
  final int quantityBefore;
  final int quantityAfter;
  final int delta;
  final String? reason;
}

class _StorePriceRuleHistoryEntry {
  _StorePriceRuleHistoryEntry({
    required this.id,
    required this.occurredAt,
    required this.summary,
    this.listMarkupBefore,
    required this.listMarkupAfter,
    this.floorMarkupBefore,
    required this.floorMarkupAfter,
  }) : actorDisplayName = 'fake-user';

  final String id;
  final DateTime occurredAt;
  final String summary;
  final double? listMarkupBefore;
  final double listMarkupAfter;
  final double? floorMarkupBefore;
  final double floorMarkupAfter;
  final String actorDisplayName;

  StorePriceRuleChangeHistoryEntryDto toDto({required bool isCurrent}) {
    return StorePriceRuleChangeHistoryEntryDto(
      id: id,
      occurredAt: occurredAt,
      actorDisplayName: actorDisplayName,
      summary: summary,
      listMarkupBefore: listMarkupBefore,
      listMarkupAfter: listMarkupAfter,
      floorMarkupBefore: floorMarkupBefore,
      floorMarkupAfter: floorMarkupAfter,
      isCurrent: isCurrent,
    );
  }
}

class _StorePriceRule {
  _StorePriceRule({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.listMarkupRatio,
    required this.floorMarkupRatio,
    this.status = StorePriceRuleStatus.active,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.utc(2026, 1, 1);

  final String id;
  final String tenantId;
  String name;
  double listMarkupRatio;
  double floorMarkupRatio;
  StorePriceRuleStatus status;
  DateTime updatedAt;

  StorePriceRuleDto toDto() => StorePriceRuleDto(
    id: id,
    tenantId: tenantId,
    name: name,
    status: status,
    calculationType: StorePriceCalculationType.markup,
    listMarkupRatio: listMarkupRatio,
    floorMarkupRatio: floorMarkupRatio,
    updatedAt: updatedAt,
  );
}

class FakeStoredProduct {
  FakeStoredProduct({
    required this.id,
    String? referenceId,
    required this.name,
    this.tradeName,
    required this.sku,
    required this.barcode,
    required this.baseUnit,
    this.images = const [],
    this.stockQty,
    this.baseCost,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.priceBandSourceType,
    this.isCustomOverride = false,
    this.notes,
    this.hasRequiredCustomFields = true,
    this.stockMode = FakeProductReadinessBuilder.stockModeBasic,
    this.basePriceMode = FakeProductReadinessBuilder.basePriceModeManual,
    this.pricePermissionDenied = false,
    this.businessStatus = ProductBusinessStatus.active,
    this.trackingMode = ProductTrackingMode.none,
    this.expiryRequired = false,
    this.hasInventoryMovements = false,
    DateTime? updatedAt,
  }) : floorMarkupRatio = null,
       listMarkupRatio = null,
       floorAfterVat = null,
       referenceId = referenceId ?? id,
       updatedAt = updatedAt ?? DateTime.utc(2026, 1, 1);

  final String id;
  final String referenceId;
  String name;
  String? tradeName;
  String sku;
  String barcode;
  String baseUnit;
  List<String> images;
  List<ProductImageMutationInput>? imageDetails;
  int? stockQty;
  int stockVersion = 1;
  List<FakeStockMovement> stockMovements = const [];
  double? baseCost;
  int? listBeforeVat;
  int? floorBeforeVat;
  int? listAfterVat;
  int? floorAfterVat;
  PriceBandSourceType? priceBandSourceType;
  double? listMarkupRatio;
  double? floorMarkupRatio;
  String? storePriceRuleId;
  String? storePriceRuleName;
  bool isCustomOverride;
  bool useStoreRule = false;
  String? notes;
  String? description;
  final bool hasRequiredCustomFields;
  final StockMode stockMode;
  final BasePriceMode basePriceMode;
  final bool pricePermissionDenied;
  ProductBusinessStatus businessStatus;
  ProductTrackingMode trackingMode;
  bool expiryRequired;
  bool hasInventoryMovements;
  List<ProductChangeHistoryEntryDto> statusHistory = const [];
  DateTime updatedAt;
  int version = 1;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;
  bool get hasBaseUnit => baseUnit.trim().isNotEmpty;
  bool get hasImages => images.isNotEmpty;
  bool get hasStock => stockQty != null;
  bool get hasBasePrice => baseCost != null;
  bool get hasPriceBandAmounts => listBeforeVat != null && listAfterVat != null;

  int? get basePriceVersion =>
      baseCost == null ? null : StorePriceSuggestionCalculator.basePriceVersionFor(baseCost!);
}

final class _MarkupConfig {
  const _MarkupConfig({
    required this.listMarkupRatio,
    this.floorMarkupRatio,
  });

  final double listMarkupRatio;
  final double? floorMarkupRatio;
}

String _foldForSearch(String value) {
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final codeUnit in lower.codeUnits) {
    buffer.writeCharCode(_foldCodeUnit(codeUnit));
  }
  return buffer.toString();
}

int _foldCodeUnit(int codeUnit) {
  const map = <int, int>{
    0x00E0: 0x61, 0x00E1: 0x61, 0x00E2: 0x61, 0x00E3: 0x61,
    0x00E8: 0x65, 0x00E9: 0x65, 0x00EA: 0x65, 0x00EC: 0x69,
    0x00ED: 0x69, 0x00F2: 0x6F, 0x00F3: 0x6F, 0x00F4: 0x6F,
    0x00F5: 0x6F, 0x00F9: 0x75, 0x00FA: 0x75, 0x00FD: 0x79,
    0x0111: 0x64, 0x0103: 0x61, 0x01A1: 0x6F, 0x01B0: 0x75,
    0x1EA1: 0x61, 0x1EA3: 0x61, 0x1EA5: 0x61, 0x1EA7: 0x61,
    0x1EA9: 0x61, 0x1EAB: 0x61, 0x1EAD: 0x61, 0x1EAF: 0x61,
    0x1EB1: 0x61, 0x1EB3: 0x61, 0x1EB5: 0x61, 0x1EB7: 0x61,
    0x1EB9: 0x65, 0x1EBB: 0x65, 0x1EBD: 0x65, 0x1EBF: 0x65,
    0x1EC1: 0x65, 0x1EC3: 0x65, 0x1EC5: 0x65, 0x1EC7: 0x65,
    0x1EC9: 0x69, 0x1ECB: 0x69, 0x1ECD: 0x6F, 0x1ECF: 0x6F,
    0x1ED1: 0x6F, 0x1ED3: 0x6F, 0x1ED5: 0x6F, 0x1ED7: 0x6F,
    0x1ED9: 0x6F, 0x1EDB: 0x6F, 0x1EDD: 0x6F, 0x1EDF: 0x6F,
    0x1EE1: 0x6F, 0x1EE3: 0x6F, 0x1EE5: 0x75, 0x1EE7: 0x75,
    0x1EE9: 0x75, 0x1EEB: 0x75, 0x1EED: 0x75, 0x1EEF: 0x75,
    0x1EF1: 0x75, 0x1EF3: 0x79, 0x1EF5: 0x79, 0x1EF7: 0x79,
    0x1EF9: 0x79,
  };
  return map[codeUnit] ?? codeUnit;
}

/// Fake in-memory backend for catalog tests, replacing FakeCatalogModule.
class FakeCatalogBackend {
  FakeCatalogBackend({this.scenario = FakeCatalogScenario.guidedCreateOk})
    : _customFieldStore = FakeCatalogCustomFieldStore(
        scenario: scenario,
        productsMissingRequiredCount: 3,
      ),
      _tenantUnits = [
        FakeTenantUnit(id: 'unit-lo', name: 'Lọ'),
        FakeTenantUnit(id: 'unit-hop', name: 'Hộp'),
        FakeTenantUnit(id: 'unit-vi', name: 'Vỉ'),
        FakeTenantUnit(id: 'unit-inactive', name: 'Thùng', isActive: false),
      ],
      _productUnits = [
        FakeProductUnit(
          id: 'product-1-base',
          productId: 'product-1',
          name: 'Hộp',
          conversionRateToBase: 1,
          isBaseUnit: true,
          isActive: true,
          listBeforeVat: 120000,
          listAfterVat: 120000,
          floorBeforeVat: 95000,
          priceBandSourceType: PriceBandSourceType.manual,
        ),
        FakeProductUnit(
          id: 'product-1-unit-vi',
          productId: 'product-1',
          name: 'Vỉ',
          conversionRateToBase: 10,
          isBaseUnit: false,
          isActive: true,
          listBeforeVat: 1200000,
          listAfterVat: 1200000,
          floorBeforeVat: 950000,
          priceBandSourceType: PriceBandSourceType.manual,
        ),
        FakeProductUnit(
          id: 'product-1-unit-thung',
          productId: 'product-1',
          name: 'Thùng',
          conversionRateToBase: 100,
          isBaseUnit: false,
          isActive: false,
        ),
        FakeProductUnit(
          id: 'product-9-base',
          productId: 'product-9',
          name: 'Lọ',
          conversionRateToBase: 1,
          isBaseUnit: true,
          isActive: true,
        ),
        FakeProductUnit(
          id: 'product-9-hop',
          productId: 'product-9',
          name: 'Hộp',
          conversionRateToBase: 10,
          isBaseUnit: false,
          isActive: true,
        ),
        FakeProductUnit(
          id: 'product-10-base',
          productId: 'product-10',
          name: 'Lọ',
          conversionRateToBase: 1,
          isBaseUnit: true,
          isActive: true,
          listBeforeVat: 120000,
          listAfterVat: 120000,
          floorBeforeVat: 95000,
          priceBandSourceType: PriceBandSourceType.manual,
          isCustomOverride: true,
        ),
        FakeProductUnit(
          id: 'product-10-hop',
          productId: 'product-10',
          name: 'Hộp',
          conversionRateToBase: 10,
          isBaseUnit: false,
          isActive: true,
        ),
        FakeProductUnit(
          id: 'product-11-base',
          productId: 'product-11',
          name: 'Lọ',
          conversionRateToBase: 1,
          isBaseUnit: true,
          isActive: true,
        ),
        FakeProductUnit(
          id: 'product-11-hop',
          productId: 'product-11',
          name: 'Hộp',
          conversionRateToBase: 10,
          isBaseUnit: false,
          isActive: true,
          hasConversionRate: false,
        ),
        FakeProductUnit(
          id: 'product-snapshot-partial-base',
          productId: 'product-snapshot-partial',
          name: 'Lọ',
          conversionRateToBase: 1,
          isBaseUnit: true,
          isActive: true,
          listBeforeVat: 100000,
        ),
      ],
      _products = [
        FakeStoredProduct(
          id: 'product-1',
          name: 'Amoxicillin 500mg',
          tradeName: 'Amox 500',
          sku: 'SP0001',
          barcode: '8930000000001',
          baseUnit: 'Hộp',
          images: ['https://picsum.photos/200/300'],
          stockQty: 150,
          baseCost: 80000,
          listBeforeVat: 120000,
          listAfterVat: 120000,
          floorBeforeVat: 95000,
          notes: 'Hàng dễ vỡ, bảo quản nhiệt độ thường',
          updatedAt: DateTime.utc(2026, 6, 1),
        ),
        FakeStoredProduct(
          id: 'product-2',
          name: 'Paracetamol 500mg',
          tradeName: 'Panadol',
          sku: 'SP0002',
          barcode: '8930000000002',
          baseUnit: 'Vỉ',
          images: ['https://picsum.photos/200/301'],
          stockQty: 400,
          baseCost: 15000,
          listBeforeVat: 25000,
          listAfterVat: 25000,
          floorBeforeVat: 18000,
          priceBandSourceType: PriceBandSourceType.manual,
          isCustomOverride: true,
          updatedAt: DateTime.utc(2026, 5, 15),
        ),
        FakeStoredProduct(
          id: 'product-3',
          name: 'Ceftriaxone 1g',
          tradeName: 'Cef 1g',
          sku: 'SP0003',
          barcode: '8930000000003',
          baseUnit: 'Lọ',
          images: [],
          stockQty: 0,
          baseCost: 45000,
          listBeforeVat: 70000,
          listAfterVat: 70000,
          floorBeforeVat: 55000,
          priceBandSourceType: PriceBandSourceType.manual,
          updatedAt: DateTime.utc(2026, 4, 20),
        ),
        FakeStoredProduct(
          id: 'product-4',
          name: 'Vitamin B Complex',
          tradeName: 'VB Complex',
          sku: 'SP0004',
          barcode: '8930000000004',
          baseUnit: 'Chai',
          images: ['https://picsum.photos/200/302'],
          stockQty: 80,
          baseCost: 25000,
          updatedAt: DateTime.utc(2026, 3, 10),
        ),
        FakeStoredProduct(
          id: 'product-5',
          name: 'Ibuprofen 400mg',
          tradeName: 'Brufen',
          sku: 'SP0005',
          barcode: '8930000000005',
          baseUnit: 'Hộp',
          images: ['https://picsum.photos/200/303'],
          stockQty: 200,
          baseCost: 30000,
          listBeforeVat: 45000,
          listAfterVat: 45000,
          floorBeforeVat: 35000,
          priceBandSourceType: PriceBandSourceType.manual,
          businessStatus: ProductBusinessStatus.inactive,
          updatedAt: DateTime.utc(2026, 2, 5),
        ),
        FakeStoredProduct(
          id: 'product-6',
          name: 'Thuốc thiếu đơn vị',
          tradeName: 'No Unit Drug',
          sku: 'SP0006',
          barcode: '8930000000006',
          baseUnit: '',
          images: ['https://picsum.photos/200/304'],
          updatedAt: DateTime.utc(2026, 1, 20),
        ),
        FakeStoredProduct(
          id: 'product-7',
          name: 'Thuốc thiếu giá',
          tradeName: 'No Price Drug',
          sku: 'SP0007',
          barcode: '8930000000007',
          baseUnit: 'Lọ',
          images: ['https://picsum.photos/200/305'],
          stockQty: 10,
          updatedAt: DateTime.utc(2026, 1, 15),
        ),
        FakeStoredProduct(
          id: 'product-8',
          name: 'Thuốc giá vốn module',
          tradeName: 'Costing Drug',
          sku: 'SP0008',
          barcode: '8930000000008',
          baseUnit: 'Lọ',
          images: ['https://picsum.photos/200/306'],
          stockQty: 20,
          basePriceMode: FakeProductReadinessBuilder.basePriceModeCosting,
          updatedAt: DateTime.utc(2026, 1, 10),
        ),
        FakeStoredProduct(
          id: 'product-9',
          name: 'Thuốc multi UOM',
          tradeName: 'Multi UOM Drug',
          sku: 'SP0009',
          barcode: '8930000000009',
          baseUnit: 'Lọ',
          images: ['https://picsum.photos/200/307'],
          stockQty: 50,
          baseCost: 10000,
          updatedAt: DateTime.utc(2026, 1, 5),
        ),
        FakeStoredProduct(
          id: 'product-10',
          name: 'Thuốc band partial',
          tradeName: 'Partial Band Drug',
          sku: 'SP0010',
          barcode: '8930000000010',
          baseUnit: 'Lọ',
          images: ['https://picsum.photos/200/308'],
          stockQty: 30,
          baseCost: 80000,
          listBeforeVat: 120000,
          listAfterVat: 120000,
          floorBeforeVat: 95000,
          priceBandSourceType: PriceBandSourceType.manual,
          isCustomOverride: true,
          updatedAt: DateTime.utc(2026, 1, 4),
        ),
        FakeStoredProduct(
          id: 'product-11',
          name: 'Thuốc band warn',
          tradeName: 'Warn Band Drug',
          sku: 'SP0011',
          barcode: '8930000000011',
          baseUnit: 'Lọ',
          images: ['https://picsum.photos/200/309'],
          stockQty: 25,
          baseCost: 100000,
          updatedAt: DateTime.utc(2026, 1, 3),
        ),
        FakeStoredProduct(
          id: 'product-12',
          name: 'Doxycycline 100mg',
          tradeName: 'Doxy 100',
          sku: 'SP0012',
          barcode: '8930000000012',
          baseUnit: 'Hộp',
          images: ['https://picsum.photos/200/310'],
          stockQty: 15,
          baseCost: 22000,
          listBeforeVat: 35000,
          listAfterVat: 35000,
          floorBeforeVat: 28000,
          businessStatus: ProductBusinessStatus.inactive,
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
        FakeStoredProduct(
          id: 'product-snapshot-partial',
          name: 'Snapshot Partial Band',
          tradeName: 'Partial Band',
          sku: 'SP0013',
          barcode: '8930000000013',
          baseUnit: 'Lọ',
          images: ['https://picsum.photos/200/311'],
          stockQty: 5,
          baseCost: 80000,
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ],
      _storeRules = {
        'tenant-1': _StorePriceRule(
          id: 'rule-tenant-1',
          tenantId: 'tenant-1',
          name: 'Mặc định bán lẻ',
          listMarkupRatio: 0.5,
          floorMarkupRatio: 0.25,
        ),
      } {
    if (scenario == FakeCatalogScenario.pccProfileMaintenanceImages) {
      final product = _products.firstWhere((p) => p.id == 'product-1');
      product.images = [
        'https://cdn.fake/image-a.webp',
        'https://cdn.fake/image-b.webp',
      ];
    }
    if (scenario == FakeCatalogScenario.searchUnaccentVietnamese) {
      final product = _products.firstWhere((p) => p.id == 'product-1');
      product.name = 'Amôxicillin 500mg';
      product.tradeName = 'Amôx 500';
    }
    if (scenario == FakeCatalogScenario.e2eCfValuesOk) {
      _seedE2eCustomFieldConfig();
    } else if (scenario == FakeCatalogScenario.e2eCfValuesSaveOk) {
      _seedE2eCustomFieldConfig(addNumberField: true);
    } else if (scenario == FakeCatalogScenario.e2eCfValuesRequired) {
      _seedE2eCustomFieldConfig(requireThanhPhan: true);
    } else if (scenario == FakeCatalogScenario.e2eCfValuesMultiRequired) {
      _seedE2eCustomFieldConfig(requireThanhPhan: true, requireBaoQuan: true);
    }

    if (scenario == FakeCatalogScenario.customFieldSearchDisplay ||
        scenario == FakeCatalogScenario.customFieldSearchable ||
        scenario == FakeCatalogScenario.customFieldFilterable ||
        scenario == FakeCatalogScenario.customFieldSnapshot) {
      _customFieldStore.seedSearchContractData();
    } else if (scenario == FakeCatalogScenario.customFieldFilterInactive) {
      _customFieldStore.seedSearchContractData(deactivateFilterableField: true);
    }
  }

  void _seedE2eCustomFieldConfig({
    bool addNumberField = false,
    bool requireThanhPhan = false,
    bool requireBaoQuan = false,
  }) {
    _customFieldStore.initializeTemplate('tenant-1');
    final config = _customFieldStore.listConfigSync('tenant-1');
    final drugGroup = config.groups.firstWhere(
      (group) => group.name == 'Thông tin thuốc',
    );

    if (addNumberField) {
      _customFieldStore.upsertField(
        'tenant-1',
        groupId: drugGroup.groupId,
        name: 'Thời gian ngưng sử dụng',
        fieldType: CustomFieldType.number,
      );
    }

    if (requireThanhPhan) {
      final thanhPhan = drugGroup.fields.firstWhere(
        (field) => field.name == 'Thành phần',
      );
      _customFieldStore.configureAttributes(
        'tenant-1',
        fieldId: thanhPhan.fieldId,
        isRequired: true,
        isSearchable: false,
        isFilterable: false,
        displayOnList: false,
      );
    }

    if (requireBaoQuan) {
      final storageGroup = config.groups.firstWhere(
        (group) => group.name == 'Quy cách & bảo quản',
      );
      final baoQuan = storageGroup.fields.firstWhere(
        (field) => field.name == 'Bảo quản',
      );
      _customFieldStore.configureAttributes(
        'tenant-1',
        fieldId: baoQuan.fieldId,
        isRequired: true,
        isSearchable: false,
        isFilterable: false,
        displayOnList: false,
      );
    }
  }

  final String scenario;
  final FakeCatalogCustomFieldStore _customFieldStore;
  final List<FakeTenantUnit> _tenantUnits;
  final List<FakeProductUnit> _productUnits;
  final List<FakeStoredProduct> _products;
  final Map<String, _StorePriceRule> _storeRules;
  final Map<String, List<_StorePriceRuleHistoryEntry>> _storeRuleHistory = {};
  int _nextStoreRuleHistoryId = 1;
  int _nextProductId = 11;
  int _nextProductUnitId = 1;

  FakeCatalogCustomFieldStore get customFieldStore => _customFieldStore;
  List<FakeStoredProduct> get products => _products;
  List<FakeProductUnit> get productUnits => _productUnits;
  List<FakeTenantUnit> get tenantUnits => _tenantUnits;

  // ---------------------------------------------------------------------------
  // Helper assertions & finding
  // ---------------------------------------------------------------------------

  void _assertCatalogReadPermission() {
    if (scenario == FakeCatalogScenario.customFieldSearchPermissionDenied ||
        scenario == FakeCatalogScenario.scnContractE06U04PermissionDenied) {
      throw const AppException(AppErrorCode.noPermission, serverMessage: 'Permission denied');
    }
  }

  void _assertViewHistoryPermission() {
    if (scenario == FakeCatalogScenario.scnContractE07U04Fr03_01 ||
        scenario == FakeCatalogScenario.scnContractE07U04PermissionDenied) {
      throw const AppException(AppErrorCode.noPermission, serverMessage: 'Permission denied');
    }
  }

  FakeStoredProduct? _findProduct(String productId) {
    for (final product in _products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  FakeProductUnit? _findProductUnit(String productId, String unitId) {
    for (final unit in _productUnits) {
      if (unit.productId == productId && unit.id == unitId) {
        return unit;
      }
    }
    return null;
  }

  FakeProductUnit? _findActiveProductUnitByName(String productId, String name) {
    final normalized = _normalizeUnitName(name);
    for (final unit in _productUnits) {
      if (unit.productId == productId &&
          unit.isActive &&
          _normalizeUnitName(unit.name) == normalized) {
        return unit;
      }
    }
    return null;
  }

  bool _productHasStructuredUnits(String productId) {
    return _productUnits.any((unit) => unit.productId == productId);
  }

  String _normalizeUnitName(String name) => name.trim().toLowerCase();

  String _normalizeSku(String sku) => sku.trim().toUpperCase();

  String? _optionalText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _markUpdated(FakeStoredProduct product) {
    product.updatedAt = DateTime.utc(2026, 7, 1);
    product.version += 1;
  }

  bool _productHasRequiredCustomFields(FakeStoredProduct product) {
    if (!product.hasRequiredCustomFields) {
      return false;
    }
    return _customFieldStore.hasRequiredValues(product.id);
  }

  bool _isSupportedImageContentType(String contentType) {
    const supported = {'image/jpeg', 'image/png', 'image/webp'};
    return supported.contains(contentType.trim().toLowerCase());
  }

  ReadinessSummaryDto _readinessSummaryFor(FakeStoredProduct product) {
    return FakeCatalogProductBuilder.readinessSummaryFor(
      productId: product.id,
      productName: product.name,
      hasBaseUnit: product.hasBaseUnit,
      hasImages: product.hasImages,
      hasStock: product.hasStock,
      hasBasePrice: product.hasBasePrice,
      hasPriceBand: _productHasPriceBand(product),
      hasRequiredCustomFields: _productHasRequiredCustomFields(product),
      stockMode: product.stockMode,
      basePriceMode: product.basePriceMode,
    );
  }

  ProductReadinessViewDto _buildReadinessView(FakeStoredProduct product) {
    final facts = ProductReadinessFacts(
      productId: product.id,
      productName: product.name,
      hasBaseUnit: product.hasBaseUnit,
      hasImages: product.hasImages,
      hasStock: product.hasStock,
      hasBasePrice: product.hasBasePrice,
      hasPriceBand: _productHasPriceBand(product),
      hasRequiredCustomFields: _productHasRequiredCustomFields(product),
      stockMode: product.stockMode,
      basePriceMode: product.basePriceMode,
    );
    final readiness = ProductReadinessEvaluator.compute(facts);
    final perms = readinessPermissionsOf((perm) {
      if (product.pricePermissionDenied && perm == CatalogPermissions.managePricing) {
        return false;
      }
      return true;
    });
    return ProductReadinessViewAssembler.assemble(
      facts: facts,
      readiness: readiness,
      permissions: perms,
    );
  }

  // ---------------------------------------------------------------------------
  // ProductRepository handlers
  // ---------------------------------------------------------------------------

  Future<ProductSearchResultDto> handleSearch({
    ProductSearchCriteria? criteria,
    int limit = 50,
    int offset = 0,
  }) async {
    _assertCatalogReadPermission();
    if (scenario == FakeCatalogScenario.searchEmpty) {
      return const ProductSearchResultDto(items: [], totalCount: 0);
    }

    final effectiveCriteria = criteria ?? ProductSearchCriteria();
    final filtered = _visibleProducts(effectiveCriteria);
    final items = filtered.map(_toListItemDto).toList(growable: false);

    final start = offset.clamp(0, items.length);
    final end = (offset + limit).clamp(0, items.length);
    final page = items.sublist(start, end);

    int? readyToSellCount;
    int? incompleteCount;
    int? inactiveCount;

    if (effectiveCriteria.keyword == null &&
        effectiveCriteria.readinessFilter == null &&
        effectiveCriteria.customFieldFilters.isEmpty) {
      final allCatalogVisible = _products.where((p) => !p.isSoftDeleted).toList();
      final activeProducts = allCatalogVisible
          .where((p) => p.businessStatus == ProductBusinessStatus.active)
          .toList();
      readyToSellCount = activeProducts
          .where((p) => _readinessSummaryFor(p).status == ReadinessStatus.readyToSell)
          .length;
      incompleteCount = activeProducts.length - readyToSellCount;
      inactiveCount = allCatalogVisible
          .where((p) => p.businessStatus == ProductBusinessStatus.inactive)
          .length;
    }

    return ProductSearchResultDto(
      items: page,
      totalCount: items.length,
      readyToSellCount: readyToSellCount,
      incompleteCount: incompleteCount,
      inactiveCount: inactiveCount,
    );
  }

  Future<List<CustomFieldFilterOptionDto>> handleListCustomFieldFilterOptions({
    int maxOptionsPerField = 50,
  }) async {
    _assertCatalogReadPermission();
    return _customFieldStore.listFilterOptions(
      tenantId: 'tenant-1',
      maxOptionsPerField: maxOptionsPerField,
    );
  }

  Future<List<ProductDuplicateMatchDto>> handleCheckDuplicateCodes({
    String? sku,
    String? barcode,
    String? excludeProductId,
  }) async {
    if (scenario == FakeCatalogScenario.scnContractE07U01Fr01_03) {
      throw const AppException(AppErrorCode.noPermission, serverMessage: 'Permission denied');
    }

    final trimmedSku = sku?.trim();
    final finalSku = (trimmedSku != null && trimmedSku.isNotEmpty) ? _normalizeSku(trimmedSku) : null;
    final trimmedBarcode = barcode?.trim();
    final finalBarcode = (trimmedBarcode != null && trimmedBarcode.isNotEmpty) ? trimmedBarcode : null;

    final matches = <ProductDuplicateMatchDto>[];
    for (final product in _products) {
      if (product.isSoftDeleted) continue;
      if (excludeProductId != null && product.id == excludeProductId) continue;

      if (finalSku != null && _normalizeSku(product.sku) == finalSku) {
        matches.add(
          ProductDuplicateMatchDto(
            field: ProductDuplicateField.sku,
            productId: product.id,
            productName: product.name,
            matchedValue: product.sku,
          ),
        );
      }
      if (finalBarcode != null && product.barcode == finalBarcode) {
        matches.add(
          ProductDuplicateMatchDto(
            field: ProductDuplicateField.barcode,
            productId: product.id,
            productName: product.name,
            matchedValue: product.barcode,
          ),
        );
      }
    }
    return matches;
  }

  Future<CreateGuidedProductResult> handleCreateGuided(CreateGuidedProductInput input) async {
    switch (scenario) {
      case FakeCatalogScenario.guidedCreatePermissionDenied:
      case FakeCatalogScenario.readinessPermissionDenied:
        throw const AppException(AppErrorCode.noPermission, serverMessage: 'Permission denied');
      case FakeCatalogScenario.guidedCreateDupSku:
        throw AppException(
          CatalogErrorCodes.duplicateSku,
          serverMessage: 'Duplicate SKU: "${input.sku ?? 'SKU-001'}"',
          details: {
            'value': input.sku ?? 'SKU-001',
            'existing_product_id': 'product-existing-1',
            'existing_product_name': 'Existing Product',
          },
        );
      case FakeCatalogScenario.guidedCreateDupBarcode:
        throw AppException(
          CatalogErrorCodes.duplicateBarcode,
          serverMessage: 'Duplicate barcode: "${input.barcode ?? '8901234567890'}"',
          details: {
            'value': input.barcode ?? '8901234567890',
            'existing_product_id': 'product-existing-1',
            'existing_product_name': 'Existing Product',
          },
        );
      case FakeCatalogScenario.guidedCreateDupReference:
        throw const AppException(
          CatalogErrorCodes.duplicateReferenceId,
          details: {'value': 'SP-0001'},
        );
      case FakeCatalogScenario.guidedCreateMissingName:
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'product name is required',
        );
      case FakeCatalogScenario.guidedCreateNoImages:
        return _persistCreate(input);
      case FakeCatalogScenario.readinessReadyToSell:
        return _persistCreate(
          input,
          hasStock: true,
          hasBasePrice: true,
          hasPriceBand: true,
        );
      case FakeCatalogScenario.readinessManyBlockers:
        return _persistCreate(input, hasImages: false);
      case FakeCatalogScenario.readinessAdvancedStockPending:
        return _persistCreate(
          input,
          stockMode: FakeProductReadinessBuilder.stockModeAdvanced,
        );
      case FakeCatalogScenario.readinessCostingBasePricePending:
        return _persistCreate(
          input,
          basePriceMode: FakeProductReadinessBuilder.basePriceModeCosting,
        );
      case FakeCatalogScenario.readinessMissingCustomFields:
        return _persistCreate(input, hasRequiredCustomFields: false);
      case FakeCatalogScenario.readinessNoPricePermission:
        return _persistCreate(
          input,
          hasStock: true,
          hasBasePrice: true,
          pricePermissionDenied: true,
        );
      case FakeCatalogScenario.readinessRefreshAfterUnit:
        return _persistCreate(input, hasBasePrice: true);
      case FakeCatalogScenario.guidedCreateOk:
      default:
        return _persistCreate(input);
    }
  }

  CreateGuidedProductResult _persistCreate(
    CreateGuidedProductInput input, {
    bool hasImages = true,
    bool hasStock = false,
    bool hasBasePrice = false,
    bool hasPriceBand = false,
    bool hasRequiredCustomFields = true,
    StockMode stockMode = StockMode.basic,
    BasePriceMode basePriceMode = BasePriceMode.manual,
    bool pricePermissionDenied = false,
  }) {
    final productId = 'product-new-${_nextProductId++}';
    final referenceId = 'ref-$productId';
    final images = hasImages ? input.images.map((img) => img.storageKey).toList() : <String>[];

    final baseUnitName = switch (input.baseUnit) {
      ExistingTenantUnit(:final unitId) =>
        _tenantUnits.firstWhere((unit) => unit.id == unitId).name,
      NewTenantUnit(:final name) => () {
        final normalized = _normalizeUnitName(name);
        final alreadyExists = _tenantUnits.any(
          (unit) => _normalizeUnitName(unit.name) == normalized,
        );
        if (!alreadyExists) {
          _tenantUnits.add(FakeTenantUnit(id: 'unit-new-${_tenantUnits.length + 1}', name: name));
        }
        return name;
      }(),
      null => '',
    };

    final product = FakeStoredProduct(
      id: productId,
      referenceId: referenceId,
      name: input.productName.trim(),
      tradeName: _optionalText(input.commercialName),
      sku: _normalizeSku(input.sku ?? ''),
      barcode: input.barcode?.trim() ?? '',
      baseUnit: baseUnitName,
      images: images,
      stockQty: hasStock ? 0 : null,
      baseCost: hasBasePrice ? (input.basePrice ?? 0) : input.basePrice,
      listBeforeVat: hasPriceBand ? 1 : input.listBeforeVat,
      floorBeforeVat: hasPriceBand ? 1 : input.floorBeforeVat,
      listAfterVat: hasPriceBand ? 1 : input.listBeforeVat,
      priceBandSourceType: hasPriceBand ? PriceBandSourceType.manual : input.priceBandSourceType,
      notes: _optionalText(input.note),
      hasRequiredCustomFields: hasRequiredCustomFields,
      stockMode: stockMode,
      basePriceMode: basePriceMode,
      pricePermissionDenied: pricePermissionDenied,
      trackingMode: input.trackingMode,
      expiryRequired: input.expiryRequired,
    );

    _ensureUniqueSku(product, product.sku);
    _ensureUniqueBarcode(product, product.barcode);

    if (product.hasBaseUnit && baseUnitName.isNotEmpty) {
      final baseUnit = FakeProductUnit(
        id: '$productId-base',
        productId: productId,
        name: baseUnitName,
        conversionRateToBase: 1,
        isBaseUnit: true,
        isActive: true,
      );
      _productUnits.add(baseUnit);
    }

    final sourceType = input.priceBandSourceType;
    if (product.hasBaseUnit && sourceType == PriceBandSourceType.ruleBased) {
      product
        ..listBeforeVat = 0
        ..floorBeforeVat = 0
        ..listAfterVat = 0
        ..floorAfterVat = 0
        ..priceBandSourceType = PriceBandSourceType.ruleBased
        ..storePriceRuleId = null
        ..storePriceRuleName = null
        ..listMarkupRatio = null
        ..floorMarkupRatio = null
        ..isCustomOverride = false;

      final rule = _storeRuleForTenant('tenant-1');
      if (product.baseCost != null && rule != null && rule.status == StorePriceRuleStatus.active) {
        final prices = StorePriceSuggestionCalculator.suggest(
          basePrice: product.baseCost!,
          listMarkupRatio: rule.listMarkupRatio,
          floorMarkupRatio: rule.floorMarkupRatio,
        );
        product
          ..listBeforeVat = prices.listBeforeVat
          ..floorBeforeVat = prices.floorBeforeVat
          ..listAfterVat = prices.listBeforeVat
          ..floorAfterVat = prices.floorBeforeVat
          ..storePriceRuleId = rule.id
          ..storePriceRuleName = rule.name;
      }
      _recordGuidedPriceBandHistory(product: product, actorId: 'user-1');
    } else if (product.hasBaseUnit && sourceType == PriceBandSourceType.customConfig) {
      product
        ..listBeforeVat = 0
        ..floorBeforeVat = 0
        ..listAfterVat = 0
        ..floorAfterVat = 0
        ..priceBandSourceType = PriceBandSourceType.customConfig
        ..storePriceRuleId = null
        ..storePriceRuleName = null
        ..listMarkupRatio = input.listMarkupRatio
        ..floorMarkupRatio = input.floorMarkupRatio
        ..isCustomOverride = true;

      if (product.baseCost != null && input.listMarkupRatio != null) {
        final prices = _calculateMarkup(
          basePriceForUnit: product.baseCost!,
          config: _MarkupConfig(
            listMarkupRatio: input.listMarkupRatio!,
            floorMarkupRatio: input.floorMarkupRatio,
          ),
        );
        product
          ..listBeforeVat = prices.listPrice
          ..floorBeforeVat = prices.floorPrice
          ..listAfterVat = prices.listPrice
          ..floorAfterVat = prices.floorPrice;
      }
      _recordGuidedPriceBandHistory(product: product, actorId: 'user-1');
    } else if (sourceType == PriceBandSourceType.manual) {
      product
        ..listBeforeVat = input.listBeforeVat
        ..floorBeforeVat = input.floorBeforeVat
        ..listAfterVat = input.listBeforeVat
        ..floorAfterVat = input.floorBeforeVat
        ..priceBandSourceType = sourceType
        ..storePriceRuleId = null
        ..storePriceRuleName = null
        ..listMarkupRatio = input.listMarkupRatio
        ..floorMarkupRatio = input.floorMarkupRatio
        ..isCustomOverride = false;
      if (input.listBeforeVat != null) {
        _recordGuidedPriceBandHistory(product: product, actorId: 'user-1');
      }
    }

    _products.add(product);

    if (input.customFieldValues.isNotEmpty) {
      _customFieldStore.upsertValues(
        productId: productId,
        tenantId: 'tenant-1',
        values: input.customFieldValues,
      );
    }

    final view = _buildReadinessView(product);
    return CreateGuidedProductResult(
      productId: productId,
      readinessSummary: view.readinessSummary,
    );
  }

  void _recordGuidedPriceBandHistory({
    required FakeStoredProduct product,
    required String actorId,
  }) {
    final sourceType = product.priceBandSourceType;
    final listPrice = product.listBeforeVat;
    if (sourceType == null || listPrice == null) return;

    product.statusHistory = [
      ProductChangeHistoryEntryDto(
        id: 'history-${product.id}-pricing-created',
        occurredAt: DateTime.utc(2026, 7, 16),
        actorDisplayName: actorId,
        changeType: ProductChangeHistoryAction.priceBandUpdated,
        summary: 'Tạo khung giá — ${product.baseUnit}',
        changeCategory: ProductChangeCategory.pricing,
        priceBandChange: ProductPriceBandHistoryChangeDto(
          productUnitId: '${product.id}-base',
          unitName: product.baseUnit,
          currency: 'VND',
          trigger: ProductPriceBandHistoryTrigger.direct,
          after: ProductPriceBandHistorySnapshotDto(
            sourceType: sourceType,
            listPrice: listPrice,
            floorPrice: product.floorBeforeVat,
          ),
        ),
      ),
      ...product.statusHistory,
    ];
  }

  Future<ProductImageUploadSlotDto> handleRequestImageUpload({
    required String fileName,
    required String contentType,
    required int byteSize,
  }) async {
    if (scenario == FakeCatalogScenario.scnContractE07U01Fr02_04 ||
        !_isSupportedImageContentType(contentType)) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'Unsupported image content type.');
    }
    final slotId = 'slot-${DateTime.now().millisecondsSinceEpoch}';
    return ProductImageUploadSlotDto(
      slotId: slotId,
      storageKey: 'tenant-1/staging/$slotId/original.jpeg',
      signedUploadUrl: 'https://storage.fake/upload/$slotId',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
  }

  Future<ProductImageUploadSlotDto> handleRequestMaintenanceImageUpload({
    required String productId,
    required String fileName,
    required String contentType,
    required int byteSize,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    if (_isSoftDeletedForMaintenance(product)) {
      throw const AppException(CatalogErrorCodes.productSoftDeleted, serverMessage: 'Product is soft-deleted and cannot be updated.');
    }
    if (scenario == FakeCatalogScenario.scnContractE07U01Fr02_04 ||
        !_isSupportedImageContentType(contentType)) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'Unsupported image content type.');
    }
    final slotId = 'slot-maintenance-$productId-${product.version}';
    return ProductImageUploadSlotDto(
      slotId: slotId,
      storageKey: 'tenant-1/staging/$slotId/original.jpeg',
      signedUploadUrl: 'https://storage.fake/upload/$slotId',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
  }

  Future<ProductControlCenterDto> handleGetControlCenter(String productId) async {
    if (scenario == FakeCatalogScenario.readinessPermissionDenied) {
      throw const AppException(AppErrorCode.noPermission, serverMessage: 'Permission denied');
    }
    final product = _resolveControlCenterProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    return _toControlCenterDto(product);
  }

  Future<ProductReadinessViewDto> handleGetReadiness(String productId) async {
    if (scenario == FakeCatalogScenario.readinessPermissionDenied) {
      throw const AppException(AppErrorCode.noPermission, serverMessage: 'Permission denied');
    }
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    return _buildReadinessView(product);
  }

  Future<void> handleUpdateProfile({
    required String productId,
    int? expectedVersion,
    required String productName,
    String? commercialName,
    String? sku,
    String? barcode,
    String? description,
    String? note,
    ProductTrackingMode? trackingMode,
    bool? expiryRequired,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    _ensureMaintenanceAllowed(product, expectedVersion);

    final trimmedName = productName.trim();
    if (trimmedName.isEmpty) {
      throw const AppException(CatalogErrorCodes.productNameRequired, serverMessage: 'product name is required');
    }
    final normalizedSku = _normalizeSku(_optionalText(sku) ?? '');
    final finalBarcode = _optionalText(barcode) ?? '';
    _ensureUniqueSku(product, normalizedSku);
    _ensureUniqueBarcode(product, finalBarcode);

    if ((trackingMode != null && trackingMode != product.trackingMode) ||
        (expiryRequired != null && expiryRequired != product.expiryRequired)) {
      if (product.hasInventoryMovements) {
        throw const AppException(
          CatalogErrorCodes.trackingLocked,
          serverMessage: 'Đã có biến động kho, không đổi được.',
        );
      }
      if (trackingMode != null) product.trackingMode = trackingMode;
      if (expiryRequired != null) product.expiryRequired = expiryRequired;
    }

    product.name = trimmedName;
    product.tradeName = _optionalText(commercialName);
    product.sku = normalizedSku;
    product.barcode = finalBarcode;
    product.description = _optionalText(description);
    product.notes = _optionalText(note);
    _markUpdated(product);
  }

  Future<void> handleUpdateImages({
    required String productId,
    int? expectedVersion,
    required List<ProductImageMutationInput> images,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    _ensureMaintenanceAllowed(product, expectedVersion);

    product.imageDetails = images;
    product.images = images.map((image) => image.url ?? image.storageKey).toList(growable: false);
    _markUpdated(product);
  }

  Future<void> handleDeactivate({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings = false,
  }) async {
    if (scenario == FakeCatalogScenario.scnContractE07U02Fr01_03) {
      throw const AppException(AppErrorCode.noPermission, serverMessage: 'Permission denied');
    }

    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    _ensureStatusChangeAllowed(product, expectedVersion);
    if (product.businessStatus == ProductBusinessStatus.inactive) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'product is already inactive');
    }

    final warnings = _businessStatusWarningsFor(product);
    if (warnings.isNotEmpty && !confirmAcknowledgeWarnings) {
      throw AppException(
        CatalogErrorCodes.statusWarningsRequireAck,
        details: {
          'warnings': warnings.map((w) => {'code': w.code, 'message': w.message}).toList(),
        },
      );
    }

    _changeProductStatus(
      product: product,
      nextStatus: ProductBusinessStatus.inactive,
      actorId: 'user-1',
      reason: reason,
      warnings: warnings,
    );
  }

  Future<void> handleReactivate({
    required String productId,
    int? expectedVersion,
    String? reason,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    if (scenario == FakeCatalogScenario.scnContractE07U02Fr02_02 && product.id == 'product-4') {
      product.businessStatus = ProductBusinessStatus.inactive;
    }
    _ensureStatusChangeAllowed(product, expectedVersion);
    if (product.businessStatus == ProductBusinessStatus.active) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'product is already active');
    }

    _changeProductStatus(
      product: product,
      nextStatus: ProductBusinessStatus.active,
      actorId: 'user-1',
      reason: reason,
    );
  }

  Future<ProductDeletionEligibilityDto> handleCheckDeletionEligibility(String productId) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    return _deletionEligibilityFor(product);
  }

  Future<void> handleDelete({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings = false,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    _ensureSoftDeleteVersion(product, expectedVersion);
    if (product.isSoftDeleted) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'product is already soft-deleted');
    }

    final eligibility = _deletionEligibilityFor(product);
    if (!eligibility.canDelete) {
      throw const AppException(
        CatalogErrorCodes.productDeleteBlocked,
        serverMessage: 'Không thể xóa sản phẩm vì có ràng buộc.',
      );
    }
    if (eligibility.issues.any((i) => i.severity == ProductDeletionIssueSeverity.warning) &&
        !confirmAcknowledgeWarnings) {
      throw const AppException(
        CatalogErrorCodes.productDeleteBlocked,
        serverMessage: 'Cần xác nhận cảnh báo trước khi xóa.',
      );
    }

    product.businessStatus = ProductBusinessStatus.softDeleted;
    _markUpdated(product);

    final historyEntry = ProductChangeHistoryEntryDto(
      id: 'history-${product.id}-soft-delete-${product.version}',
      occurredAt: product.updatedAt,
      actorDisplayName: 'user-1',
      changeType: ProductChangeHistoryAction.softDeleted,
      summary: 'Xóa mềm sản phẩm',
      valueBefore: 'false',
      valueAfter: 'true',
    );
    product.statusHistory = [historyEntry, ...product.statusHistory];
  }

  Future<void> handleRestore({
    required String productId,
    int? expectedVersion,
    String? reason,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    _prepareSoftDeletedRestoreScenario(product);
    _ensureSoftDeleteVersion(product, expectedVersion);
    if (!product.isSoftDeleted) {
      throw const AppException(CatalogErrorCodes.productRestoreBlocked, serverMessage: 'product is not soft-deleted');
    }
    _ensureUniqueActiveSku(product, product.sku);
    _ensureUniqueActiveBarcode(product, product.barcode);

    product.businessStatus = ProductBusinessStatus.inactive;
    _markUpdated(product);

    final historyEntry = ProductChangeHistoryEntryDto(
      id: 'history-${product.id}-restore-${product.version}',
      occurredAt: product.updatedAt,
      actorDisplayName: 'user-1',
      changeType: ProductChangeHistoryAction.restored,
      summary: 'Khôi phục sản phẩm đã xóa mềm',
      valueBefore: 'true',
      valueAfter: 'false',
    );
    product.statusHistory = [historyEntry, ...product.statusHistory];
  }

  Future<ProductChangeHistoryResultDto> handleGetChangeHistory({
    required String productId,
    int limit = 50,
    int offset = 0,
    List<String>? changeCategories,
  }) async {
    _assertViewHistoryPermission();

    if (scenario == FakeCatalogScenario.scnContractE07U04Validation) {
      if (limit < 1 || limit > 100) {
        throw const AppException(AppErrorCode.validation, serverMessage: 'Limit must be between 1 and 100.');
      }
      if (offset < 0) {
        throw const AppException(AppErrorCode.validation, serverMessage: 'Offset must be zero or greater.');
      }
    }

    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }

    final maskPricing =
        scenario == FakeCatalogScenario.scnContractE07U04Fr03_02 || product.pricePermissionDenied;

    var entries = _buildFullChangeHistoryForProduct(product);
    if (changeCategories != null && changeCategories.isNotEmpty) {
      final allowed = changeCategories.toSet();
      entries = entries
          .where((entry) => entry.changeCategory != null && allowed.contains(entry.changeCategory!.name))
          .toList(growable: false);
    }

    entries = entries
        .map((entry) => _maskChangeHistoryEntry(entry: entry, maskPricing: maskPricing))
        .toList(growable: false);

    entries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final start = offset.clamp(0, entries.length);
    final end = (offset + limit).clamp(0, entries.length);
    final page = entries.sublist(start, end);

    return ProductChangeHistoryResultDto(
      productId: productId,
      items: page,
      totalCount: entries.length,
    );
  }

  Future<List<SellableProductDto>> handleSearchSellable({
    required String storeId,
    String? keyword,
    int limit = 50,
    int offset = 0,
  }) async {
    _assertCatalogReadPermission();
    final kw = keyword?.trim().toLowerCase();
    final matches = _products.where((p) {
      if (p.isSoftDeleted || p.businessStatus == ProductBusinessStatus.inactive) return false;
      if (kw == null || kw.isEmpty) return true;
      return p.name.toLowerCase().contains(kw) ||
          (p.tradeName?.toLowerCase().contains(kw) ?? false) ||
          p.sku.toLowerCase().contains(kw) ||
          p.barcode.toLowerCase().contains(kw);
    }).skip(offset).take(limit).map(_toSellableProductDto).toList();

    return matches;
  }

  Future<List<SellableProductDto>> handleResolveSellableBarcode({
    required String storeId,
    required String barcode,
  }) async {
    _assertCatalogReadPermission();
    final trimmed = barcode.trim();
    final matches = _products.where((p) {
      if (p.isSoftDeleted || p.businessStatus == ProductBusinessStatus.inactive) return false;
      return p.barcode == trimmed;
    }).map(_toSellableProductDto).toList();

    return matches;
  }

  Future<List<SellableProductUnitDto>> handleListSellableUnits({
    required String storeId,
    required String productId,
  }) async {
    _assertCatalogReadPermission();
    final units = _productUnits
        .where((u) => u.productId == productId && u.isActive)
        .map(_toSellableProductUnitDto)
        .toList();
    return units;
  }

  Future<List<SellableProductResolutionDto>> handleResolveSellable({
    required String storeId,
    required List<String> productIds,
  }) async {
    _assertCatalogReadPermission();
    final resolutions = <SellableProductResolutionDto>[];
    for (final id in productIds) {
      final p = _findProduct(id);
      if (p == null || p.isSoftDeleted) {
        resolutions.add(
          SellableProductResolutionDto(
            productId: id,
            resolution: SellableProductResolution.notFound,
          ),
        );
      } else if (p.businessStatus == ProductBusinessStatus.inactive) {
        resolutions.add(
          SellableProductResolutionDto(
            productId: id,
            resolution: SellableProductResolution.notSellable,
            notSellable: NotSellableProductDto(
              productId: id,
              sku: p.sku,
              displayName: p.name,
              blockReason: 'Sản phẩm đã ngừng kinh doanh',
            ),
          ),
        );
      } else {
        resolutions.add(
          SellableProductResolutionDto(
            productId: id,
            resolution: SellableProductResolution.sellable,
            product: _toSellableProductDto(p),
          ),
        );
      }
    }
    return resolutions;
  }

  SellableProductDto _toSellableProductDto(FakeStoredProduct product) {
    final units = _productUnits
        .where((u) => u.productId == product.id && u.isActive)
        .map(_toSellableProductUnitDto)
        .toList();

    return SellableProductDto(
      productId: product.id,
      sku: product.sku,
      displayName: product.name,
      tradeName: product.tradeName,
      isSellable: product.businessStatus == ProductBusinessStatus.active,
      blockReason: null,
      currencyCode: 'VND',
      listPriceMinor: (product.listAfterVat ?? 0) * 100,
      floorPriceMinor: (product.floorAfterVat ?? 0) * 100,
      availableStockMicros: (product.stockQty ?? 0) * 1000000,
      units: units,
    );
  }

  SellableProductUnitDto _toSellableProductUnitDto(FakeProductUnit unit) {
    return SellableProductUnitDto(
      productUnitId: unit.id,
      unitCode: unit.name,
      unitName: unit.name,
      barcode: null,
      isDefault: unit.isBaseUnit,
      isActive: unit.isActive,
      isSellable: unit.isActive,
      blockReason: null,
      listPriceMinor: (unit.listAfterVat ?? 0) * 100,
      floorPriceMinor: (unit.floorAfterVat ?? 0) * 100,
      availableStockMicros: null,
    );
  }

  // ---------------------------------------------------------------------------
  // MeasurementUnitRepository handlers
  // ---------------------------------------------------------------------------

  Future<List<TenantMeasurementUnitDto>> handleListTenantUnits({
    String? keyword,
    int limit = 50,
  }) async {
    final kw = keyword?.trim().toLowerCase();
    final units = _tenantUnits
        .where((unit) {
          if (kw == null || kw.isEmpty) return true;
          return unit.name.toLowerCase().contains(kw);
        })
        .take(limit);

    return units
        .map(
          (unit) => TenantMeasurementUnitDto(
            id: unit.id,
            name: unit.name,
            isActive: unit.isActive,
          ),
        )
        .toList(growable: false);
  }

  Future<ProductUnitsDto> handleListProductUnits(
    String productId, {
    bool includeInactive = false,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    return _productUnitsDto(product, includeInactive: includeInactive);
  }

  Future<void> handleSetBaseUnit(String productId, BaseUnitSelection selection) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    if (product.hasBaseUnit) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'already has a base unit',
      );
    }

    late final String unitName;
    if (selection is ExistingTenantUnit) {
      final unit = _tenantUnits.firstWhere(
        (item) => item.id == selection.unitId,
        orElse: () => throw const AppException(AppErrorCode.validation, serverMessage: 'Measurement unit not found.'),
      );
      if (!unit.isActive) {
        throw const AppException(AppErrorCode.validation, serverMessage: 'Measurement unit is inactive.');
      }
      unitName = unit.name;
    } else if (selection is NewTenantUnit) {
      final name = selection.name.trim();
      if (name.isEmpty) {
        throw const AppException(AppErrorCode.validation, serverMessage: 'Unit name must not be empty.');
      }
      final normalized = _normalizeUnitName(name);
      final existing = _tenantUnits.where((unit) => _normalizeUnitName(unit.name) == normalized).firstOrNull;
      if (existing != null || scenario == FakeCatalogScenario.setBaseUnitDuplicate) {
        throw AppException(
          CatalogErrorCodes.duplicateProductUnit,
          details: {'value': name},
        );
      }
      final newId = 'unit-new-${_tenantUnits.length + 1}';
      _tenantUnits.add(FakeTenantUnit(id: newId, name: name));
      unitName = name;
    }

    product.baseUnit = unitName;
    final baseUnit = FakeProductUnit(
      id: '${product.id}-base',
      productId: product.id,
      name: unitName,
      conversionRateToBase: 1,
      isBaseUnit: true,
      isActive: true,
    );
    _productUnits.add(baseUnit);

    if (!product.pricePermissionDenied &&
        product.priceBandSourceType == null &&
        baseUnit.priceBandSourceType == null) {
      baseUnit
        ..listBeforeVat = 0
        ..floorBeforeVat = 0
        ..listAfterVat = 0
        ..floorAfterVat = 0
        ..priceBandSourceType = PriceBandSourceType.ruleBased
        ..storePriceRuleId = null
        ..storePriceRuleName = null
        ..listMarkupRatio = null
        ..floorMarkupRatio = null
        ..isCustomOverride = false;
      _syncProductPriceBandSummary(product);
      if (product.hasBasePrice) {
        _recalculateFormulaPriceBandsForProduct(
          product: product,
          tenantId: 'tenant-1',
        );
      }
    }
  }

  Future<void> handleAddConversionUnit({
    required String productId,
    required String unitName,
    required double conversionRateToBase,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    if (!product.hasBaseUnit) {
      throw const AppException(CatalogErrorCodes.missingBaseUnit);
    }

    final trimmed = unitName.trim();
    if (trimmed.isEmpty) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'Unit name must not be empty.');
    }
    if (conversionRateToBase <= 0) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'conversion rate must be greater than zero');
    }

    final duplicate = _findActiveProductUnitByName(product.id, trimmed);
    if (duplicate != null) {
      throw AppException(
        CatalogErrorCodes.duplicateProductUnit,
        details: {'value': trimmed},
      );
    }

    final unit = FakeProductUnit(
      id: '${product.id}-unit-new-${_nextProductUnitId++}',
      productId: product.id,
      name: trimmed,
      conversionRateToBase: conversionRateToBase,
      isBaseUnit: false,
      isActive: true,
    );
    _productUnits.add(unit);
  }

  Future<void> handleDeactivateConversionUnit({
    required String productId,
    required String productUnitId,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }

    final unit = _findProductUnit(productId, productUnitId);
    if (unit == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product unit not found');
    }
    if (unit.isBaseUnit) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'Base unit cannot be deactivated here.');
    }

    unit.isActive = false;
  }

  Future<void> handleReactivateConversionUnit({
    required String productId,
    required String productUnitId,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }

    final unit = _findProductUnit(productId, productUnitId);
    if (unit == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product unit not found');
    }
    if (unit.isBaseUnit) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'Base unit cannot be reactivated here.');
    }
    if (unit.conversionRateToBase <= 0) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'conversion rate must be greater than zero');
    }

    final duplicate = _findActiveProductUnitByName(product.id, unit.name);
    if (duplicate != null && duplicate.id != unit.id) {
      throw AppException(
        CatalogErrorCodes.duplicateProductUnit,
        details: {'value': unit.name},
      );
    }

    unit.isActive = true;
  }

  Future<void> handleDeleteConversionUnit({
    required String productId,
    required String productUnitId,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }

    final unit = _findProductUnit(productId, productUnitId);
    if (unit == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product unit not found');
    }
    if (unit.isBaseUnit) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'Base unit cannot be deleted here.');
    }
    if (unit.hasPriceBandAmounts || unit.hasTransactionUsage) {
      throw const AppException(
        CatalogErrorCodes.conversionUnitDeleteBlocked,
        serverMessage: 'Không thể xóa đơn vị này vì đã có dữ liệu phụ thuộc. Hãy dùng "Tắt đơn vị" để bảo toàn lịch sử.',
      );
    }

    _productUnits.remove(unit);
  }

  ProductUnitsDto _productUnitsDto(FakeStoredProduct product, {required bool includeInactive}) {
    final units = _productUnits
        .where((unit) => unit.productId == product.id && (includeInactive || unit.isActive))
        .map(_toProductUnitDto)
        .toList(growable: false);

    return ProductUnitsDto(
      productId: product.id,
      baseUnitName: product.baseUnit,
      units: units,
    );
  }

  ProductUnitDto _toProductUnitDto(FakeProductUnit unit) {
    return ProductUnitDto(
      id: unit.id,
      name: unit.name,
      conversionRateToBase: unit.conversionRateToBase,
      isBaseUnit: unit.isBaseUnit,
      isActive: unit.isActive,
    );
  }

  // ---------------------------------------------------------------------------
  // CustomFieldRepository handlers
  // ---------------------------------------------------------------------------

  Future<CustomFieldConfigViewDto> handleListConfig() async {
    return _customFieldStore.listConfig('tenant-1');
  }

  Future<void> handleInitializeTemplate({String? templateId}) async {
    return _customFieldStore.initializeTemplate('tenant-1', templateId: templateId);
  }

  Future<void> handleUpsertGroup({
    String? groupId,
    required String name,
    int? sortOrder,
    String? iconKey,
    String? description,
    bool isActive = true,
  }) async {
    return _customFieldStore.upsertGroup(
      'tenant-1',
      groupId: groupId,
      name: name,
      sortOrder: sortOrder ?? 0,
      iconKey: iconKey,
      description: description,
      isActive: isActive,
    );
  }

  Future<void> handleReorderGroups(List<String> orderedGroupIds) async {
    return _customFieldStore.reorderGroups('tenant-1', orderedGroupIds);
  }

  Future<CustomFieldDefinitionDto> handleUpsertField({
    required String groupId,
    String? fieldId,
    required String name,
    required CustomFieldType fieldType,
    List<CustomFieldSelectOptionDto> options = const [],
    bool isActive = true,
  }) async {
    return _customFieldStore.upsertField(
      'tenant-1',
      groupId: groupId,
      fieldId: fieldId,
      name: name,
      fieldType: fieldType,
      singleSelectOptions: options.map((o) => o.label).toList(),
      isActive: isActive,
    );
  }

  Future<void> handleConfigureAttributes({
    required String fieldId,
    required bool isRequired,
    required bool isSearchable,
    required bool isFilterable,
    required bool displayOnList,
  }) async {
    return _customFieldStore.configureAttributes(
      'tenant-1',
      fieldId: fieldId,
      isRequired: isRequired,
      isSearchable: isSearchable,
      isFilterable: isFilterable,
      displayOnList: displayOnList,
    );
  }

  Future<void> handleReorderFields({
    required String groupId,
    required List<String> orderedFieldIds,
  }) async {
    return _customFieldStore.reorderFields(
      'tenant-1',
      groupId: groupId,
      orderedFieldIds: orderedFieldIds,
    );
  }

  Future<ProductCustomFieldValuesDto> handleGetProductValues(
    String productId, {
    bool includeInactiveValues = false,
  }) async {
    return _customFieldStore.getValues(
      tenantId: 'tenant-1',
      productId: productId,
      includeInactiveValues: includeInactiveValues,
    );
  }

  Future<void> handleUpsertProductValues({
    required String productId,
    required List<ProductCustomFieldValueInput> values,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    return _customFieldStore.upsertValues(
      productId: productId,
      tenantId: 'tenant-1',
      values: values,
    );
  }

  // ---------------------------------------------------------------------------
  // ProductPriceRepository handlers
  // ---------------------------------------------------------------------------

  Future<void> handleSetManualBasePrice({
    required String productId,
    required double basePrice,
    String currency = 'VND',
  }) async {
    if (basePrice < 0) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'base price cannot be negative');
    }
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    if (!product.hasBaseUnit) {
      throw const AppException(CatalogErrorCodes.missingBaseUnit);
    }
    product.baseCost = basePrice;
    _recalculateFormulaPriceBandsForProduct(
      product: product,
      tenantId: 'tenant-1',
    );
  }

  Future<ProductUnitPriceBandsDto> handleListUnitPriceBands(String productId) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    if (!product.hasBaseUnit) {
      throw const AppException(CatalogErrorCodes.missingBaseUnit);
    }

    final structuredUnits = _activeUnitsForProduct(product.id);
    if (structuredUnits.isEmpty) {
      final syntheticId = '${product.id}-base';
      return ProductUnitPriceBandsDto(
        productId: product.id,
        baseUnitName: product.baseUnit,
        basePrice: product.baseCost,
        rows: [
          ProductUnitPriceBandRowDto(
            productUnitId: syntheticId,
            unitName: product.baseUnit,
            isBaseUnit: true,
            isActive: true,
            basePrice: product.baseCost,
            listBeforeVat: product.listBeforeVat,
            floorBeforeVat: product.floorBeforeVat,
            listAfterVat: product.listAfterVat,
            floorAfterVat: product.floorAfterVat,
            isMissing: !_productHasPriceBand(product),
            sourceType: product.priceBandSourceType,
            storePriceRuleName: product.storePriceRuleName,
            listMarkupRatio: product.listMarkupRatio,
            floorMarkupRatio: product.floorMarkupRatio,
            isCustomOverride: product.isCustomOverride,
          ),
        ],
      );
    }

    return ProductUnitPriceBandsDto(
      productId: product.id,
      baseUnitName: product.baseUnit,
      basePrice: product.baseCost,
      rows: structuredUnits.map((unit) => _toPriceBandRowDto(product, unit)).toList(growable: false),
    );
  }

  ProductUnitPriceBandRowDto _toPriceBandRowDto(FakeStoredProduct product, FakeProductUnit unit) {
    return ProductUnitPriceBandRowDto(
      productUnitId: unit.id,
      unitName: unit.name,
      isBaseUnit: unit.isBaseUnit,
      isActive: unit.isActive,
      basePrice: _comparableBasePriceForUnit(product, unit),
      listBeforeVat: unit.listBeforeVat,
      floorBeforeVat: unit.floorBeforeVat,
      listAfterVat: unit.listAfterVat,
      floorAfterVat: unit.floorAfterVat,
      isMissing: !_unitHasMaterializedPriceBand(product, unit),
      sourceType: unit.priceBandSourceType,
      storePriceRuleName: unit.storePriceRuleName,
      listMarkupRatio: unit.listMarkupRatio,
      floorMarkupRatio: unit.floorMarkupRatio,
      isCustomOverride: unit.isCustomOverride,
    );
  }

  Future<ProductPriceBandSnapshotDto> handleGetPriceBandSnapshot(
    List<ProductPriceBandSnapshotRequest> items,
  ) async {
    _assertCatalogReadPermission();
    if (scenario == FakeCatalogScenario.scnContractE06U04Validation) {
      if (items.isEmpty) {
        throw const AppException(AppErrorCode.validation, serverMessage: 'At least one item is required.');
      }
      if (items.length > 100) {
        throw const AppException(AppErrorCode.validation, serverMessage: 'At most 100 items can be read at once.');
      }
    }

    final capturedAt = DateTime.now().toUtc();
    final snapshotItems = items
        .map((item) => _buildPriceBandSnapshotItem(item: item, capturedAt: capturedAt))
        .toList(growable: false);

    return ProductPriceBandSnapshotDto(items: snapshotItems);
  }

  ProductPriceBandSnapshotItemDto _buildPriceBandSnapshotItem({
    required ProductPriceBandSnapshotRequest item,
    required DateTime capturedAt,
  }) {
    final product = _findProduct(item.productId);
    if (product == null || product.isSoftDeleted) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }

    final structuredUnit = _findProductUnit(item.productId, item.productUnitId);
    if (structuredUnit != null) {
      return _snapshotItemFromUnit(
        product: product,
        unit: structuredUnit,
        capturedAt: capturedAt,
      );
    }

    final syntheticBaseId = '${product.id}-base';
    if (item.productUnitId == syntheticBaseId) {
      if (!product.hasBaseUnit) {
        throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
      }
      return ProductPriceBandSnapshotItemDto(
        productId: product.id,
        productUnitId: syntheticBaseId,
        unitName: product.baseUnit,
        currency: 'VND',
        listBeforeVat: product.listBeforeVat,
        listBeforeVatMissing: product.listBeforeVat == null,
        floorBeforeVat: product.floorBeforeVat,
        floorBeforeVatMissing: product.floorBeforeVat == null,
        floorBeforeVatHidden: product.pricePermissionDenied,
        listAfterVat: product.listAfterVat,
        floorAfterVat: product.floorAfterVat,
        isUnitActive: true,
        productBusinessStatus: product.businessStatus,
        capturedAt: capturedAt,
      );
    }

    throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product unit not found');
  }

  ProductPriceBandSnapshotItemDto _snapshotItemFromUnit({
    required FakeStoredProduct product,
    required FakeProductUnit unit,
    required DateTime capturedAt,
  }) {
    return ProductPriceBandSnapshotItemDto(
      productId: product.id,
      productUnitId: unit.id,
      unitName: unit.name,
      currency: 'VND',
      listBeforeVat: unit.listBeforeVat,
      listBeforeVatMissing: unit.listBeforeVat == null,
      floorBeforeVat: unit.floorBeforeVat,
      floorBeforeVatMissing: unit.floorBeforeVat == null,
      floorBeforeVatHidden: product.pricePermissionDenied,
      listAfterVat: unit.listAfterVat,
      floorAfterVat: unit.floorAfterVat,
      isUnitActive: unit.isActive,
      productBusinessStatus: product.businessStatus,
      capturedAt: capturedAt,
    );
  }

  Future<void> handleSetUnitPriceBand({
    required String productId,
    String? productUnitId,
    PriceBandSourceType sourceType = PriceBandSourceType.manual,
    int? listBeforeVat,
    int? listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    double? listMarkupRatio,
    double? floorMarkupRatio,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    if (!product.hasBaseUnit) {
      throw const AppException(CatalogErrorCodes.missingBaseUnit);
    }

    if (_productHasStructuredUnits(product.id)) {
      final unitId = productUnitId ?? _resolveBaseUnit(product.id)?.id;
      final unit = unitId == null ? null : _findProductUnit(product.id, unitId);
      if (unit == null) {
        throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product unit not found');
      }
      if (!unit.isActive) {
        throw const AppException(CatalogErrorCodes.inactiveProductUnit);
      }

      final values = _resolvePriceBandValues(
        product: product,
        unit: unit,
        sourceType: sourceType,
        listBeforeVat: listBeforeVat,
        listAfterVat: listAfterVat,
        floorBeforeVat: floorBeforeVat,
        floorAfterVat: floorAfterVat,
        listMarkupRatio: listMarkupRatio,
        floorMarkupRatio: floorMarkupRatio,
      );

      // Q6: PriceBandWarningsRequireAcknowledgmentException is dropped; save directly.
      unit
        ..listBeforeVat = values.listPrice
        ..floorBeforeVat = values.floorPrice
        ..listAfterVat = values.listPrice
        ..floorAfterVat = values.floorPrice
        ..priceBandSourceType = sourceType
        ..storePriceRuleId = null
        ..storePriceRuleName = null
        ..listMarkupRatio = listMarkupRatio
        ..floorMarkupRatio = floorMarkupRatio
        ..isCustomOverride = sourceType == PriceBandSourceType.customConfig;

      _syncProductPriceBandSummary(product);
      return;
    }

    final syntheticUnit = FakeProductUnit(
      id: '${product.id}-base',
      productId: product.id,
      name: product.baseUnit,
      conversionRateToBase: 1,
      isBaseUnit: true,
      isActive: true,
    );
    final values = _resolvePriceBandValues(
      product: product,
      unit: syntheticUnit,
      sourceType: sourceType,
      listBeforeVat: listBeforeVat,
      listAfterVat: listAfterVat,
      floorBeforeVat: floorBeforeVat,
      floorAfterVat: floorAfterVat,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
    );

    // Q6: save directly.
    product
      ..listBeforeVat = values.listPrice
      ..floorBeforeVat = values.floorPrice
      ..listAfterVat = values.listPrice
      ..floorAfterVat = values.floorPrice
      ..priceBandSourceType = sourceType
      ..storePriceRuleId = null
      ..storePriceRuleName = null
      ..listMarkupRatio = listMarkupRatio
      ..floorMarkupRatio = floorMarkupRatio
      ..isCustomOverride = sourceType == PriceBandSourceType.customConfig;
  }

  ({int? listPrice, int? floorPrice}) _resolvePriceBandValues({
    required FakeStoredProduct product,
    required FakeProductUnit unit,
    required PriceBandSourceType sourceType,
    int? listBeforeVat,
    int? listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    double? listMarkupRatio,
    double? floorMarkupRatio,
  }) {
    switch (sourceType) {
      case PriceBandSourceType.ruleBased:
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Vui lòng dùng lệnh áp dụng khung giá cửa hàng.',
        );
      case PriceBandSourceType.customConfig:
        if (listMarkupRatio == null) {
          throw const AppException(AppErrorCode.validation, serverMessage: 'Cấu hình tỷ lệ riêng không hợp lệ.');
        }
        final basePrice = _comparableBasePriceForUnit(product, unit);
        if (basePrice == null) {
          return (listPrice: 0, floorPrice: 0);
        }
        final prices = _calculateMarkup(
          basePriceForUnit: basePrice,
          config: _MarkupConfig(
            listMarkupRatio: listMarkupRatio,
            floorMarkupRatio: floorMarkupRatio,
          ),
        );
        return (listPrice: prices.listPrice, floorPrice: prices.floorPrice);
      case PriceBandSourceType.manual:
        if (listMarkupRatio != null || floorMarkupRatio != null) {
          throw const AppException(AppErrorCode.validation, serverMessage: 'Giá thủ công không được có nguồn công thức.');
        }
        if (listBeforeVat == null || listAfterVat == null) {
          throw const AppException(AppErrorCode.validation, serverMessage: 'Giá niêm yết là bắt buộc.');
        }
        if (floorBeforeVat != null && floorBeforeVat > listBeforeVat) {
          throw const AppException(CatalogErrorCodes.floorGreaterThanList);
        }
        return (listPrice: listBeforeVat, floorPrice: floorBeforeVat);
    }
  }

  Future<ProductUnitPriceSuggestionDto> handleSuggestUnitPrice({
    required String productId,
    String? productUnitId,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    if (!product.hasBaseUnit) {
      throw const AppException(CatalogErrorCodes.missingBaseUnit);
    }

    final targetUnit = _resolveUnitForPricing(productId: product.id, productUnitId: productUnitId);
    final unitName = targetUnit?.name ?? product.baseUnit;
    final unitId = targetUnit?.id ?? productUnitId;
    final scaledBase = targetUnit == null
        ? (product.baseCost ?? 0)
        : (_comparableBasePriceForUnit(product, targetUnit) ?? product.baseCost ?? 0);

    if (scenario == FakeCatalogScenario.scnContractE06U02Fr02_02 || !product.hasBasePrice) {
      return ProductUnitPriceSuggestionDto(
        productId: product.id,
        productUnitId: unitId,
        unitName: unitName,
        basePrice: scaledBase,
        currency: 'VND',
        canSuggest: false,
        unavailableReason: 'Cần có Giá cơ sở định giá trước',
      );
    }

    final rule = _storeRuleForTenant('tenant-1');
    if (rule == null || rule.status != StorePriceRuleStatus.active) {
      return ProductUnitPriceSuggestionDto(
        productId: product.id,
        productUnitId: unitId,
        unitName: unitName,
        basePrice: scaledBase,
        currency: 'VND',
        canSuggest: false,
        unavailableReason: rule == null
            ? 'Tenant chưa có Store Price Rule'
            : 'Store Price Rule đang không hoạt động',
      );
    }

    final prices = StorePriceSuggestionCalculator.suggest(
      basePrice: scaledBase,
      listMarkupRatio: rule.listMarkupRatio,
      floorMarkupRatio: rule.floorMarkupRatio,
    );

    return ProductUnitPriceSuggestionDto(
      productId: product.id,
      productUnitId: unitId,
      unitName: unitName,
      basePrice: scaledBase,
      currency: 'VND',
      suggestedListBeforeVat: prices.listBeforeVat,
      suggestedFloorBeforeVat: prices.floorBeforeVat,
      storePriceRuleId: rule.id,
      storePriceRuleName: rule.name,
      basePriceVersion: product.basePriceVersion,
      canSuggest: true,
    );
  }

  Future<void> handleApplyStorePriceRule({
    required String productId,
    String? productUnitId,
    String? storePriceRuleId,
    int? basePriceVersion,
    bool confirmOverwrite = false,
  }) async {
    final product = _findProduct(productId);
    if (product == null) {
      throw const AppException(CatalogErrorCodes.productNotFound, serverMessage: 'Product not found');
    }
    if (!product.hasBaseUnit) {
      throw const AppException(CatalogErrorCodes.missingBaseUnit);
    }
    if (!product.hasBasePrice) {
      throw const AppException(CatalogErrorCodes.missingBasePrice);
    }

    final rule = _storeRuleForTenant('tenant-1');
    if (rule == null) {
      throw const AppException(CatalogErrorCodes.storePriceRuleNotFound);
    }
    if (rule.status != StorePriceRuleStatus.active) {
      throw const AppException(CatalogErrorCodes.storePriceRuleInactive);
    }
    if (storePriceRuleId != null && storePriceRuleId != rule.id) {
      throw const AppException(CatalogErrorCodes.storePriceRuleNotFound);
    }

    if (scenario == FakeCatalogScenario.scnContractE06U02Fr03_03 ||
        (basePriceVersion != null && basePriceVersion != product.basePriceVersion)) {
      throw const AppException(CatalogErrorCodes.staleBasePrice);
    }

    if (_productHasPriceBand(product) && !confirmOverwrite) {
      throw AppException(
        CatalogErrorCodes.priceBandOverwriteRequired,
        details: {
          'existing_list_after_vat': product.listAfterVat,
          'existing_floor_after_vat': product.floorAfterVat,
        },
      );
    }

    final targetUnit = _resolveUnitForPricing(productId: product.id, productUnitId: productUnitId);
    final scaledBase = targetUnit == null
        ? product.baseCost!
        : (_comparableBasePriceForUnit(product, targetUnit) ?? product.baseCost!);

    final prices = StorePriceSuggestionCalculator.suggest(
      basePrice: scaledBase,
      listMarkupRatio: rule.listMarkupRatio,
      floorMarkupRatio: rule.floorMarkupRatio,
    );

    if (targetUnit != null) {
      targetUnit
        ..listBeforeVat = prices.listBeforeVat
        ..floorBeforeVat = prices.floorBeforeVat
        ..listAfterVat = prices.listBeforeVat
        ..floorAfterVat = prices.floorBeforeVat
        ..priceBandSourceType = PriceBandSourceType.ruleBased
        ..storePriceRuleId = rule.id
        ..storePriceRuleName = rule.name
        ..listMarkupRatio = null
        ..floorMarkupRatio = null
        ..isCustomOverride = false;
      _syncProductPriceBandSummary(product);
    } else {
      product
        ..listBeforeVat = prices.listBeforeVat
        ..floorBeforeVat = prices.floorBeforeVat
        ..listAfterVat = prices.listBeforeVat
        ..floorAfterVat = prices.floorBeforeVat
        ..priceBandSourceType = PriceBandSourceType.ruleBased
        ..storePriceRuleId = rule.id
        ..storePriceRuleName = rule.name
        ..listMarkupRatio = null
        ..floorMarkupRatio = null
        ..isCustomOverride = false;
    }
  }

  Future<StorePriceRuleDto?> handleGetStorePriceRule() async {
    final rule = _storeRuleForTenant('tenant-1');
    return rule?.toDto();
  }

  Future<StorePriceRuleDto> handleSetStorePriceRule({
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  }) async {
    if (scenario == FakeCatalogScenario.scnContractE06U02Fr01_02 ||
        listMarkupRatio < 0 ||
        floorMarkupRatio < 0) {
      throw const AppException(AppErrorCode.validation, serverMessage: 'Tỷ lệ cộng thêm không hợp lệ.');
    }
    if (floorMarkupRatio > listMarkupRatio) {
      throw const AppException(CatalogErrorCodes.floorGreaterThanList, serverMessage: 'markup ratios are invalid');
    }

    final existing = _storeRules['tenant-1'];
    final isCreate = existing == null;
    final isNoOp = !isCreate &&
        existing.name == name &&
        existing.listMarkupRatio == listMarkupRatio &&
        existing.floorMarkupRatio == floorMarkupRatio &&
        existing.status == status;

    final listBefore = existing?.listMarkupRatio;
    final floorBefore = existing?.floorMarkupRatio;

    if (existing != null) {
      existing
        ..name = name
        ..listMarkupRatio = listMarkupRatio
        ..floorMarkupRatio = floorMarkupRatio
        ..status = status
        ..updatedAt = DateTime.utc(2026, 7, 6);
      if (!isNoOp) {
        _appendStoreRuleHistory(
          tenantId: 'tenant-1',
          summary: 'Cập nhật khung giá cửa hàng',
          listBefore: listBefore,
          listAfter: listMarkupRatio,
          floorBefore: floorBefore,
          floorAfter: floorMarkupRatio,
        );
        _recalculateRuleBasedPriceBands(existing);
      }
      return existing.toDto();
    }

    final rule = _StorePriceRule(
      id: 'rule-tenant-1',
      tenantId: 'tenant-1',
      name: name,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
      status: status,
      updatedAt: DateTime.utc(2026, 7, 6),
    );
    _storeRules['tenant-1'] = rule;
    _appendStoreRuleHistory(
      tenantId: 'tenant-1',
      summary: 'Tạo khung giá cửa hàng',
      listAfter: listMarkupRatio,
      floorAfter: floorMarkupRatio,
    );
    return rule.toDto();
  }

  Future<StorePriceRuleChangeHistoryResultDto> handleGetStorePriceRuleHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final history = _storeRuleHistory['tenant-1'] ?? const [];
    final sorted = [...history]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final newestId = sorted.isEmpty ? null : sorted.first.id;
    final page = sorted.skip(offset).take(limit).toList();

    return StorePriceRuleChangeHistoryResultDto(
      items: page.map((entry) => entry.toDto(isCurrent: entry.id == newestId)).toList(growable: false),
      totalCount: history.length,
    );
  }

  // ---------------------------------------------------------------------------
  // Pricing helpers & calculations
  // ---------------------------------------------------------------------------

  _StorePriceRule? _storeRuleForTenant(String tenantId) {
    final rule = _storeRules[tenantId];
    if (scenario == FakeCatalogScenario.scnContractE06U02Fr03_02 && rule != null) {
      rule.status = StorePriceRuleStatus.inactive;
    }
    return rule;
  }

  void _appendStoreRuleHistory({
    required String tenantId,
    required String summary,
    double? listBefore,
    required double listAfter,
    double? floorBefore,
    required double floorAfter,
  }) {
    final history = _storeRuleHistory.putIfAbsent(tenantId, () => []);
    history.add(
      _StorePriceRuleHistoryEntry(
        id: 'srh-${_nextStoreRuleHistoryId++}',
        occurredAt: DateTime.utc(2026, 7, 6, history.length + 9),
        summary: summary,
        listMarkupBefore: listBefore,
        listMarkupAfter: listAfter,
        floorMarkupBefore: floorBefore,
        floorMarkupAfter: floorAfter,
      ),
    );
  }

  FakeProductUnit? _resolveUnitForPricing({
    required String productId,
    String? productUnitId,
  }) {
    if (productUnitId != null) {
      for (final unit in _productUnits) {
        if (unit.productId == productId && unit.id == productUnitId) {
          return unit;
        }
      }
    }
    return _resolveBaseUnit(productId);
  }

  FakeProductUnit? _resolveBaseUnit(String productId) {
    for (final unit in _productUnits) {
      if (unit.productId == productId && unit.isBaseUnit) {
        return unit;
      }
    }
    return null;
  }

  double? _comparableBasePriceForUnit(FakeStoredProduct product, FakeProductUnit unit) {
    if (!product.hasBasePrice) return null;
    if (unit.isBaseUnit) return product.baseCost;
    if (!unit.hasConversionRate || unit.conversionRateToBase <= 0) return null;
    return StorePriceSuggestionCalculator.scaleBasePriceForUnit(
      basePricePerBaseUnit: product.baseCost!,
      conversionRateToBase: unit.conversionRateToBase,
    );
  }

  ({int listPrice, int? floorPrice}) _calculateMarkup({
    required num basePriceForUnit,
    required _MarkupConfig config,
  }) {
    return (
      listPrice: (basePriceForUnit * (1 + config.listMarkupRatio)).round(),
      floorPrice: config.floorMarkupRatio == null
          ? null
          : (basePriceForUnit * (1 + config.floorMarkupRatio!)).round(),
    );
  }

  void _recalculateFormulaPriceBandsForProduct({
    required FakeStoredProduct product,
    required String tenantId,
  }) {
    final rule = _storeRules[tenantId];
    final activeRule = rule != null && rule.status == StorePriceRuleStatus.active ? rule : null;
    for (final unit in _activeUnitsForProduct(product.id)) {
      _MarkupConfig? config;
      if (unit.priceBandSourceType == PriceBandSourceType.customConfig &&
          unit.listMarkupRatio != null) {
        config = _MarkupConfig(
          listMarkupRatio: unit.listMarkupRatio!,
          floorMarkupRatio: unit.floorMarkupRatio,
        );
      } else if (unit.priceBandSourceType == PriceBandSourceType.ruleBased && activeRule != null) {
        config = _MarkupConfig(
          listMarkupRatio: activeRule.listMarkupRatio,
          floorMarkupRatio: activeRule.floorMarkupRatio,
        );
      }
      final basePrice = _comparableBasePriceForUnit(product, unit);
      if (config == null || basePrice == null) continue;
      final prices = _calculateMarkup(basePriceForUnit: basePrice, config: config);
      unit
        ..listBeforeVat = prices.listPrice
        ..floorBeforeVat = prices.floorPrice
        ..listAfterVat = prices.listPrice
        ..floorAfterVat = prices.floorPrice;
      if (unit.priceBandSourceType == PriceBandSourceType.ruleBased && activeRule != null) {
        unit
          ..storePriceRuleId = activeRule.id
          ..storePriceRuleName = activeRule.name;
      }
    }

    if (!_productHasStructuredUnits(product.id)) {
      _MarkupConfig? config;
      if (product.priceBandSourceType == PriceBandSourceType.customConfig &&
          product.listMarkupRatio != null) {
        config = _MarkupConfig(
          listMarkupRatio: product.listMarkupRatio!,
          floorMarkupRatio: product.floorMarkupRatio,
        );
      } else if (product.priceBandSourceType == PriceBandSourceType.ruleBased && activeRule != null) {
        config = _MarkupConfig(
          listMarkupRatio: activeRule.listMarkupRatio,
          floorMarkupRatio: activeRule.floorMarkupRatio,
        );
      }
      if (config != null && product.baseCost != null) {
        final prices = _calculateMarkup(basePriceForUnit: product.baseCost!, config: config);
        product
          ..listBeforeVat = prices.listPrice
          ..floorBeforeVat = prices.floorPrice
          ..listAfterVat = prices.listPrice
          ..floorAfterVat = prices.floorPrice;
        if (product.priceBandSourceType == PriceBandSourceType.ruleBased && activeRule != null) {
          product
            ..storePriceRuleId = activeRule.id
            ..storePriceRuleName = activeRule.name;
        }
      }
    }
    _syncProductPriceBandSummary(product);
  }

  void _recalculateRuleBasedPriceBands(_StorePriceRule rule) {
    if (rule.status != StorePriceRuleStatus.active) return;
    for (final product in _products) {
      _recalculateFormulaPriceBandsForProduct(product: product, tenantId: rule.tenantId);
    }
  }

  void _syncProductPriceBandSummary(FakeStoredProduct product) {
    final baseUnit = _resolveBaseUnit(product.id);
    if (baseUnit != null && baseUnit.priceBandSourceType != null) {
      product
        ..listBeforeVat = baseUnit.listBeforeVat
        ..floorBeforeVat = baseUnit.floorBeforeVat
        ..listAfterVat = baseUnit.listAfterVat
        ..floorAfterVat = baseUnit.floorAfterVat
        ..priceBandSourceType = baseUnit.priceBandSourceType
        ..storePriceRuleId = baseUnit.storePriceRuleId
        ..storePriceRuleName = baseUnit.storePriceRuleName
        ..listMarkupRatio = baseUnit.listMarkupRatio
        ..floorMarkupRatio = baseUnit.floorMarkupRatio
        ..isCustomOverride = baseUnit.isCustomOverride;
      return;
    }

    if (product.priceBandSourceType != null) return;

    if (!product.hasPriceBandAmounts) {
      product
        ..listBeforeVat = null
        ..floorBeforeVat = null
        ..listAfterVat = null
        ..floorAfterVat = null
        ..priceBandSourceType = null
        ..storePriceRuleId = null
        ..storePriceRuleName = null
        ..listMarkupRatio = null
        ..floorMarkupRatio = null
        ..isCustomOverride = false;
    }
  }

  bool _isMaterializedPriceBand({
    required PriceBandSourceType? sourceType,
    required int? listBeforeVat,
    required int? listAfterVat,
    required bool hasBasePrice,
  }) {
    if (sourceType == null || listBeforeVat == null || listAfterVat == null) return false;
    if (sourceType == PriceBandSourceType.manual) return true;
    if (!hasBasePrice) return false;
    return listBeforeVat > 0 && listAfterVat > 0;
  }

  bool _isPendingAutomaticPriceBand({
    required PriceBandSourceType? sourceType,
    required int? listBeforeVat,
    required int? listAfterVat,
    required bool hasBasePrice,
  }) {
    if (sourceType != PriceBandSourceType.customConfig &&
        sourceType != PriceBandSourceType.ruleBased) {
      return false;
    }
    return !_isMaterializedPriceBand(
      sourceType: sourceType,
      listBeforeVat: listBeforeVat,
      listAfterVat: listAfterVat,
      hasBasePrice: hasBasePrice,
    );
  }

  bool _unitHasMaterializedPriceBand(FakeStoredProduct product, FakeProductUnit unit) {
    return _isMaterializedPriceBand(
      sourceType: unit.priceBandSourceType,
      listBeforeVat: unit.listBeforeVat,
      listAfterVat: unit.listAfterVat,
      hasBasePrice: product.hasBasePrice,
    );
  }

  bool _productHasPriceBand(FakeStoredProduct product) {
    final activeUnits = _productUnits
        .where((unit) => unit.productId == product.id && unit.isActive)
        .toList(growable: false);
    if (activeUnits.isNotEmpty) {
      return activeUnits.every((unit) => _unitHasMaterializedPriceBand(product, unit));
    }
    return _isMaterializedPriceBand(
      sourceType: product.priceBandSourceType,
      listBeforeVat: product.listBeforeVat,
      listAfterVat: product.listAfterVat,
      hasBasePrice: product.hasBasePrice,
    );
  }

  List<FakeProductUnit> _activeUnitsForProduct(String productId) {
    return _productUnits
        .where((unit) => unit.productId == productId && unit.isActive)
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Validation, Maintenance, Status changes helpers
  // ---------------------------------------------------------------------------

  void _ensureMaintenanceAllowed(FakeStoredProduct product, int? expectedVersion) {
    if (_isSoftDeletedForMaintenance(product)) {
      throw const AppException(
        CatalogErrorCodes.productSoftDeleted,
        serverMessage: 'Product is soft-deleted and cannot be updated.',
      );
    }
    if (expectedVersion != null && expectedVersion != product.version) {
      throw AppException(
        CatalogErrorCodes.staleProductVersion,
        details: {'expected': expectedVersion, 'current': product.version},
      );
    }
  }

  bool _isSoftDeletedForMaintenance(FakeStoredProduct product) {
    return product.isSoftDeleted ||
        (scenario == FakeCatalogScenario.scnContractE07U01Fr01_04 && product.id == 'product-7');
  }

  void _ensureStatusChangeAllowed(FakeStoredProduct product, int? expectedVersion) {
    if (_isSoftDeletedForStatusChange(product)) {
      throw const AppException(
        CatalogErrorCodes.productSoftDeleted,
        serverMessage: 'Product is soft-deleted and cannot change business status.',
      );
    }
    if (expectedVersion != null && expectedVersion != product.version) {
      throw AppException(
        CatalogErrorCodes.staleProductVersion,
        details: {'expected': expectedVersion, 'current': product.version},
      );
    }
  }

  bool _isSoftDeletedForStatusChange(FakeStoredProduct product) {
    return product.isSoftDeleted ||
        (scenario == FakeCatalogScenario.scnContractE07U02Fr02_03 && product.id == 'product-7');
  }

  void _ensureSoftDeleteVersion(FakeStoredProduct product, int? expectedVersion) {
    if (expectedVersion != null && expectedVersion != product.version) {
      throw AppException(
        CatalogErrorCodes.staleProductVersion,
        details: {'expected': expectedVersion, 'current': product.version},
      );
    }
  }

  void _ensureUniqueSku(FakeStoredProduct target, String sku) {
    final normalized = _normalizeSku(sku);
    if (normalized.isEmpty) return;
    for (final product in _products) {
      if (product.id != target.id &&
          !product.isSoftDeleted &&
          _normalizeSku(product.sku) == normalized) {
        throw AppException(
          CatalogErrorCodes.duplicateSku,
          serverMessage: 'Duplicate SKU: "$sku"',
          details: {
            'value': sku,
            'existing_product_id': product.id,
            'existing_product_name': product.name,
          },
        );
      }
    }
  }

  void _ensureUniqueBarcode(FakeStoredProduct target, String barcode) {
    if (barcode.isEmpty) return;
    for (final product in _products) {
      if (product.id != target.id && !product.isSoftDeleted && product.barcode == barcode) {
        throw AppException(
          CatalogErrorCodes.duplicateBarcode,
          serverMessage: 'Duplicate barcode: "$barcode"',
          details: {
            'value': barcode,
            'existing_product_id': product.id,
            'existing_product_name': product.name,
          },
        );
      }
    }
  }

  void _ensureUniqueActiveSku(FakeStoredProduct target, String sku) {
    _ensureUniqueSku(target, sku);
  }

  void _ensureUniqueActiveBarcode(FakeStoredProduct target, String barcode) {
    _ensureUniqueBarcode(target, barcode);
  }

  List<ProductBusinessStatusWarningDto> _businessStatusWarningsFor(FakeStoredProduct product) {
    if (scenario == FakeCatalogScenario.scnContractE07U02Fr01_02 &&
        product.stockQty != null &&
        product.stockQty! > 0) {
      return const [
        ProductBusinessStatusWarningDto(
          code: 'hasStock',
          message: 'Sản phẩm vẫn còn tồn kho hiện hành.',
        ),
      ];
    }
    return const [];
  }

  void _changeProductStatus({
    required FakeStoredProduct product,
    required ProductBusinessStatus nextStatus,
    required String actorId,
    required String? reason,
    List<ProductBusinessStatusWarningDto> warnings = const [],
  }) {
    final previousStatus = product.businessStatus;
    product.businessStatus = nextStatus;
    _markUpdated(product);

    final historyEntry = ProductChangeHistoryEntryDto(
      id: 'history-${product.id}-status-${product.version}',
      occurredAt: product.updatedAt,
      actorDisplayName: actorId,
      changeType: ProductChangeHistoryAction.statusChanged,
      summary: nextStatus == ProductBusinessStatus.inactive
          ? 'Ngừng kinh doanh sản phẩm'
          : 'Kinh doanh lại sản phẩm',
      valueBefore: previousStatus.name,
      valueAfter: nextStatus.name,
    );
    product.statusHistory = [historyEntry, ...product.statusHistory];
  }

  ProductDeletionEligibilityDto _deletionEligibilityFor(FakeStoredProduct product) {
    final issues = <ProductDeletionIssueDto>[];
    String? suggestedActionId;

    if (scenario == FakeCatalogScenario.scnContractE07U03Fr01_02 && product.id == 'product-4') {
      issues.add(
        const ProductDeletionIssueDto(
          code: 'openTransaction',
          message: 'Sản phẩm đang nằm trong giao dịch mở.',
          severity: ProductDeletionIssueSeverity.blocker,
        ),
      );
    }

    if (scenario == FakeCatalogScenario.scnContractE07U03Fr01_03 && product.id == 'product-1') {
      issues.add(
        const ProductDeletionIssueDto(
          code: 'hasHistoricalTransactions',
          message: 'Sản phẩm có giao dịch lịch sử cần bảo toàn.',
          severity: ProductDeletionIssueSeverity.warning,
        ),
      );
      suggestedActionId = 'deactivate_product';
    }

    final canDelete = !issues.any(
      (issue) => issue.severity == ProductDeletionIssueSeverity.blocker,
    );
    return ProductDeletionEligibilityDto(
      productId: product.id,
      canDelete: canDelete,
      issues: issues,
      suggestedActionId: suggestedActionId,
    );
  }

  void _prepareSoftDeletedRestoreScenario(FakeStoredProduct product) {
    if (product.id != 'product-7') return;
    if (scenario == FakeCatalogScenario.scnContractE07U03Fr03_02) {
      product.businessStatus = ProductBusinessStatus.softDeleted;
      product.sku = 'SP0001';
    } else if (scenario == FakeCatalogScenario.scnContractE07U03Fr03_03) {
      product.businessStatus = ProductBusinessStatus.softDeleted;
      product.barcode = '8930000000001';
    }
  }

  // ---------------------------------------------------------------------------
  // Control center, Search and History DTO conversion helpers
  // ---------------------------------------------------------------------------

  FakeStoredProduct? _resolveControlCenterProduct(String productId) {
    if (scenario == FakeCatalogScenario.pccIncomplete) {
      return _findProduct('product-4') ?? _findProduct(productId);
    }
    if (scenario == FakeCatalogScenario.pccReadyToSell) {
      return _findProduct('product-1') ?? _findProduct(productId);
    }
    if (scenario == FakeCatalogScenario.pccProfileMaintenanceImages) {
      return _findProduct('product-1') ?? _findProduct(productId);
    }
    if (scenario == FakeCatalogScenario.pccInactive) {
      return _findProduct('product-5') ?? _findProduct(productId);
    }
    return _findProduct(productId);
  }

  ProductControlCenterDto _toControlCenterDto(FakeStoredProduct product) {
    final configuredCustomFieldCards = _customFieldStore.toActiveGroupCards(
      productId: product.id,
    );
    final customFieldCards = switch (scenario) {
      FakeCatalogScenario.pccCustomFieldCards => () {
        if (configuredCustomFieldCards.isNotEmpty) {
          return configuredCustomFieldCards;
        }
        return [
          const CustomFieldGroupCardDto(
            groupId: 'group-vet-info',
            name: 'Thông tin thuốc',
            iconKey: 'medication',
            sortOrder: 1,
            fields: [
              CustomFieldCardFieldDto(
                fieldId: 'field-withdrawal',
                name: 'Thời gian ngưng sử dụng',
                fieldType: 'text',
                displayValue: '7 ngày',
                sortOrder: 1,
              ),
            ],
          ),
        ];
      }(),
      _ => configuredCustomFieldCards,
    };

    final history = [
      ...product.statusHistory,
      ProductChangeHistoryEntryDto(
        id: 'history-${product.id}-1',
        occurredAt: product.updatedAt,
        actorDisplayName: 'Nguyễn Văn A',
        changeType: ProductChangeHistoryAction.created,
        summary: 'Tạo sản phẩm',
      ),
    ];

    final built = FakeCatalogProductBuilder.toControlCenter(
      id: product.id,
      name: product.name,
      tradeName: product.tradeName,
      sku: product.sku,
      barcode: product.barcode,
      images: product.images,
      description: product.description,
      note: product.notes,
      businessStatus: product.businessStatus,
      baseUnit: product.baseUnit,
      stockQty: product.stockQty,
      stockVersion: product.stockVersion,
      baseCost: product.baseCost,
      listBeforeVat: product.listBeforeVat,
      floorBeforeVat: product.floorBeforeVat,
      listAfterVat: product.listAfterVat,
      floorAfterVat: product.floorAfterVat,
      priceBandSourceType: product.priceBandSourceType,
      storePriceRuleName: product.storePriceRuleName,
      isCustomOverride: product.isCustomOverride,
      hasRequiredCustomFields: _productHasRequiredCustomFields(product),
      stockMode: product.stockMode,
      basePriceMode: product.basePriceMode,
      pricePermissionDenied: product.pricePermissionDenied,
      customFieldGroupCards: customFieldCards,
      changeHistoryPreview: history,
      trackingMode: product.trackingMode,
      expiryRequired: product.expiryRequired,
      hasInventoryMovements: product.hasInventoryMovements,
    );

    final readiness = _buildReadinessView(product);
    final bandConfigured = product.priceBandSourceType != null;
    return ProductControlCenterDto(
      profile: built.profile,
      units: built.units,
      stock: built.stock,
      basePrice: built.basePrice,
      priceBand: ProductPriceBandCardDto(
        listBeforeVat: product.listBeforeVat,
        floorBeforeVat: product.floorBeforeVat,
        unitName: built.priceBand.unitName,
        isMissing: !bandConfigured,
        isPendingCalculation: _isPendingAutomaticPriceBand(
          sourceType: product.priceBandSourceType,
          listBeforeVat: product.listBeforeVat,
          listAfterVat: product.listAfterVat,
          hasBasePrice: product.hasBasePrice,
        ),
        missingMessage: !bandConfigured ? 'Thiếu khung giá bán' : null,
        sourceType: product.priceBandSourceType,
        storePriceRuleName: product.storePriceRuleName,
        isCustomOverride: product.isCustomOverride,
      ),
      customFieldGroupCards: built.customFieldGroupCards,
      readinessSummary: readiness.readinessSummary,
      checklist: built.checklist,
      contextualActions: readiness.suggestedActions,
      changeHistoryPreview: built.changeHistoryPreview,
      primaryActionId: readiness.primaryActionId,
    );
  }

  List<FakeStoredProduct> _visibleProducts(ProductSearchCriteria criteria) {
    final keyword = criteria.keyword;
    final useRelevance = keyword != null && criteria.sortOrder == ProductSortOrder.relevanceDesc;
    final allowedStatuses = {
      ...criteria.businessStatuses,
      if (criteria.includeSoftDeleted) ProductBusinessStatus.softDeleted,
    };
    return _products.where((product) {
      if (!allowedStatuses.contains(product.businessStatus)) {
        return false;
      }
      if (!_matchesKeyword(product, keyword)) {
        return false;
      }
      if (!_matchesReadinessFilter(product, criteria.readinessFilter)) {
        return false;
      }
      if (criteria.customFieldFilters.isNotEmpty &&
          !_customFieldStore.matchesFilters(product.id, criteria.customFieldFilters)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      int statusRank(ProductBusinessStatus status) =>
          status == ProductBusinessStatus.active ? 0 : 1;
      final byStatus = statusRank(a.businessStatus).compareTo(statusRank(b.businessStatus));
      if (byStatus != 0) return byStatus;
      if (useRelevance) {
        final byRank = _approximateRelevanceRank(b, keyword).compareTo(
          _approximateRelevanceRank(a, keyword),
        );
        if (byRank != 0) return byRank;
      }
      final byUpdated = b.updatedAt.compareTo(a.updatedAt);
      if (byUpdated != 0) return byUpdated;
      return a.name.compareTo(b.name);
    });
  }

  bool _matchesKeyword(FakeStoredProduct product, String? keyword) {
    if (keyword == null) return true;
    final foldedKeyword = _foldForSearch(keyword);
    final fields = [
      product.name,
      product.tradeName ?? '',
      product.sku,
      product.barcode,
    ];
    for (final field in fields) {
      final foldedField = _foldForSearch(field);
      if (foldedField.contains(foldedKeyword) || field == keyword) {
        return true;
      }
    }
    return _customFieldStore.matchesSearchKeyword(product.id, keyword);
  }

  int _approximateRelevanceRank(FakeStoredProduct product, String keyword) {
    final foldedKeyword = _foldForSearch(keyword);
    final name = _foldForSearch(product.name);
    final trade = _foldForSearch(product.tradeName ?? '');
    final sku = _foldForSearch(product.sku);
    final barcode = _foldForSearch(product.barcode);
    if (name.startsWith(foldedKeyword)) return 500;
    if (name.contains(foldedKeyword)) return 400;
    if (trade.contains(foldedKeyword)) return 300;
    if (sku == foldedKeyword || sku.startsWith(foldedKeyword)) return 250;
    if (barcode == foldedKeyword || barcode.contains(foldedKeyword)) return 200;
    return 100;
  }

  bool _matchesReadinessFilter(FakeStoredProduct product, ProductReadinessFilter? filter) {
    if (filter == null) return true;
    final summary = _readinessSummaryFor(product);
    return switch (filter) {
      ProductReadinessFilter.readyToSell => summary.status == ReadinessStatus.readyToSell,
      ProductReadinessFilter.incomplete => summary.status == ReadinessStatus.incomplete,
    };
  }

  ProductListItemDto _toListItemDto(FakeStoredProduct product) {
    return FakeCatalogProductBuilder.toListItem(
      id: product.id,
      name: product.name,
      tradeName: product.tradeName,
      sku: product.sku,
      barcode: product.barcode,
      primaryImageUrl: product.images.firstOrNull,
      businessStatus: product.businessStatus,
      readinessSummary: _readinessSummaryFor(product),
      listBeforeVat: product.listBeforeVat,
      floorBeforeVat: product.floorBeforeVat,
      listAfterVat: product.listAfterVat,
      floorAfterVat: product.floorAfterVat,
      baseUnit: product.baseUnit,
      stockQuantity: product.stockQty,
      updatedAt: product.updatedAt,
      hasRequiredCustomFields: _productHasRequiredCustomFields(product),
      stockMode: product.stockMode,
      basePriceMode: product.basePriceMode,
      hasImages: product.hasImages,
      hasStock: product.hasStock,
      hasBasePrice: product.hasBasePrice,
      hasPriceBand: _productHasPriceBand(product),
      hasBaseUnit: product.hasBaseUnit,
      customFieldValues: _customFieldStore.listDisplayValuesForProduct(product.id),
    );
  }

  List<ProductChangeHistoryEntryDto> _buildFullChangeHistoryForProduct(FakeStoredProduct product) {
    if (scenario == FakeCatalogScenario.scnContractE07U04Fr02_02 && product.id == 'product-6') {
      return const [];
    }

    if (product.id != 'product-1' && scenario != FakeCatalogScenario.scnContractE07U04Fr02_01) {
      return product.statusHistory;
    }

    final seeded = <ProductChangeHistoryEntryDto>[
      ProductChangeHistoryEntryDto(
        id: 'history-${product.id}-pricing',
        occurredAt: DateTime.utc(2026, 6, 2, 10),
        actorDisplayName: 'Nguyễn Văn A',
        changeType: ProductChangeHistoryAction.priceBandUpdated,
        summary: 'Cập nhật khung giá',
        valueBefore: '120000',
        valueAfter: '125000',
        changeCategory: ProductChangeCategory.pricing,
        priceBandChange: const ProductPriceBandHistoryChangeDto(
          productUnitId: 'product-1-base',
          unitName: 'Hộp',
          currency: 'VND',
          trigger: ProductPriceBandHistoryTrigger.direct,
          before: ProductPriceBandHistorySnapshotDto(
            sourceType: PriceBandSourceType.ruleBased,
            listPrice: 120000,
            floorPrice: 95000,
          ),
          after: ProductPriceBandHistorySnapshotDto(
            sourceType: PriceBandSourceType.manual,
            listPrice: 125000,
            floorPrice: 100000,
          ),
        ),
      ),
      ProductChangeHistoryEntryDto(
        id: 'history-${product.id}-pricing-created',
        occurredAt: DateTime.utc(2026, 6, 1, 9, 30),
        actorDisplayName: 'Nguyễn Văn A',
        changeType: ProductChangeHistoryAction.priceBandUpdated,
        summary: 'Tạo khung giá — Hộp',
        changeCategory: ProductChangeCategory.pricing,
        priceBandChange: const ProductPriceBandHistoryChangeDto(
          productUnitId: 'product-1-base',
          unitName: 'Hộp',
          currency: 'VND',
          trigger: ProductPriceBandHistoryTrigger.direct,
          after: ProductPriceBandHistorySnapshotDto(
            sourceType: PriceBandSourceType.customConfig,
            listPrice: 120000,
            floorPrice: 95000,
          ),
        ),
      ),
      ProductChangeHistoryEntryDto(
        id: 'history-${product.id}-profile',
        occurredAt: DateTime.utc(2026, 6, 1, 9),
        actorDisplayName: 'Nguyễn Văn A',
        changeType: ProductChangeHistoryAction.profileUpdated,
        summary: 'Cập nhật hồ sơ sản phẩm',
        valueBefore: 'Amoxicillin 500mg',
        valueAfter: 'Amoxicillin 500mg (revised)',
        changeCategory: ProductChangeCategory.profile,
      ),
      ProductChangeHistoryEntryDto(
        id: 'history-${product.id}-created',
        occurredAt: DateTime.utc(2026, 5, 1, 8),
        actorDisplayName: 'Hệ thống',
        changeType: ProductChangeHistoryAction.created,
        summary: 'Tạo sản phẩm',
        valueAfter: product.name,
        changeCategory: ProductChangeCategory.profile,
        source: 'system',
      ),
      ...product.statusHistory,
    ];

    return seeded;
  }

  ProductChangeHistoryEntryDto _maskChangeHistoryEntry({
    required ProductChangeHistoryEntryDto entry,
    required bool maskPricing,
  }) {
    if (!maskPricing || entry.changeCategory != ProductChangeCategory.pricing) {
      return entry;
    }

    return ProductChangeHistoryEntryDto(
      id: entry.id,
      occurredAt: entry.occurredAt,
      actorDisplayName: entry.actorDisplayName,
      changeType: entry.changeType,
      summary: 'Thay đổi giá (ẩn)',
      valueBefore: null,
      valueAfter: null,
      changeCategory: entry.changeCategory,
      source: entry.source,
      isSensitiveMasked: true,
    );
  }
}
