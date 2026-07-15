import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'fake_catalog_custom_field_store.dart';
import 'fake_catalog_product_builder.dart';
import 'fake_catalog_scenario.dart';
import 'fake_product_readiness_builder.dart';

class _TenantUnit {
  _TenantUnit({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final String id;
  final String name;
  bool isActive;
}

class _ProductUnit {
  _ProductUnit({
    required this.id,
    required this.productId,
    required this.name,
    required this.conversionRateToBase,
    required this.isBaseUnit,
    required this.isActive,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    this.priceBandSourceType,
    this.listMarkupRatio,
    this.floorMarkupRatio,
    this.isCustomOverride = false,
    this.hasConversionRate = true,
    this.hasTransactionUsage = false,
  });

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

  bool get hasCompletePriceBand => listBeforeVat != null && listAfterVat != null;
}

class _StockMovement {
  const _StockMovement({
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
  final StockMovementType movementType;
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
    this.actorDisplayName = 'fake-user',
  });

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

class _StoredProduct {
  _StoredProduct({
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
    this.floorAfterVat,
    this.priceBandSourceType,
    this.listMarkupRatio,
    this.floorMarkupRatio,
    this.isCustomOverride = false,
    this.notes,
    this.hasRequiredCustomFields = true,
    this.stockMode = FakeProductReadinessBuilder.stockModeBasic,
    this.basePriceMode = FakeProductReadinessBuilder.basePriceModeManual,
    this.pricePermissionDenied = false,
    this.businessStatus = ProductBusinessStatus.active,
    DateTime? updatedAt,
  }) : referenceId = referenceId ?? id,
       updatedAt = updatedAt ?? DateTime.utc(2026, 1, 1);

  final String id;
  final String referenceId;
  String name;
  String? tradeName;
  String sku;
  String barcode;
  String baseUnit;
  List<String> images;
  List<ProductImageDto>? imageDetails;
  int? stockQty;
  int stockVersion = 1;
  List<_StockMovement> stockMovements = const [];
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
  List<ProductChangeHistoryEntryDto> statusHistory = const [];
  DateTime updatedAt;
  int version = 1;

  bool get isSoftDeleted => businessStatus.isSoftDeleted;

  bool get hasBaseUnit => baseUnit.trim().isNotEmpty;

  bool get hasImages => images.isNotEmpty;

  bool get hasStock => stockQty != null;

  bool get hasBasePrice => baseCost != null;

  bool get hasPriceBand => listBeforeVat != null && listAfterVat != null;

  int? get basePriceVersion =>
      baseCost == null ? null : StorePriceSuggestionCalculator.basePriceVersionFor(baseCost!);
}

final class FakeCatalogModule implements ICatalogModule {
  FakeCatalogModule({this.scenario = FakeCatalogScenario.guidedCreateOk})
    : _customFieldStore = FakeCatalogCustomFieldStore(
        scenario: scenario,
        productsMissingRequiredCount: 3,
      ),
      _tenantUnits = [
        _TenantUnit(id: 'unit-lo', name: 'Lọ'),
        _TenantUnit(id: 'unit-hop', name: 'Hộp'),
        _TenantUnit(id: 'unit-vi', name: 'Vỉ'),
        _TenantUnit(id: 'unit-inactive', name: 'Thùng', isActive: false),
      ],
      _productUnits = [
        _ProductUnit(
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
        _ProductUnit(
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
        _ProductUnit(
          id: 'product-1-unit-thung',
          productId: 'product-1',
          name: 'Thùng',
          conversionRateToBase: 100,
          isBaseUnit: false,
          isActive: false,
        ),
        _ProductUnit(
          id: 'product-9-base',
          productId: 'product-9',
          name: 'Lọ',
          conversionRateToBase: 1,
          isBaseUnit: true,
          isActive: true,
        ),
        _ProductUnit(
          id: 'product-9-hop',
          productId: 'product-9',
          name: 'Hộp',
          conversionRateToBase: 10,
          isBaseUnit: false,
          isActive: true,
        ),
        _ProductUnit(
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
        _ProductUnit(
          id: 'product-10-hop',
          productId: 'product-10',
          name: 'Hộp',
          conversionRateToBase: 10,
          isBaseUnit: false,
          isActive: true,
        ),
        _ProductUnit(
          id: 'product-11-base',
          productId: 'product-11',
          name: 'Lọ',
          conversionRateToBase: 1,
          isBaseUnit: true,
          isActive: true,
        ),
        _ProductUnit(
          id: 'product-11-hop',
          productId: 'product-11',
          name: 'Hộp',
          conversionRateToBase: 10,
          isBaseUnit: false,
          isActive: true,
          hasConversionRate: false,
        ),
        _ProductUnit(
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
        _StoredProduct(
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
        _StoredProduct(
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
        _StoredProduct(
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
          updatedAt: DateTime.utc(2026, 4, 20),
        ),
        _StoredProduct(
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
        _StoredProduct(
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
          businessStatus: ProductBusinessStatus.inactive,
          updatedAt: DateTime.utc(2026, 2, 5),
        ),
        _StoredProduct(
          id: 'product-6',
          name: 'Thuốc thiếu đơn vị',
          tradeName: 'No Unit Drug',
          sku: 'SP0006',
          barcode: '8930000000006',
          baseUnit: '',
          images: ['https://picsum.photos/200/304'],
          updatedAt: DateTime.utc(2026, 1, 20),
        ),
        _StoredProduct(
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
        _StoredProduct(
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
        _StoredProduct(
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
        _StoredProduct(
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
        _StoredProduct(
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
        _StoredProduct(
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
        _StoredProduct(
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
  }) {
    _customFieldStore.initializeTemplate(
      InitializeCustomFieldTemplateCommand(tenantId: 'tenant-1'),
    );

    final config = _customFieldStore.listConfig('tenant-1');
    final drugGroup = config.groups.firstWhere(
      (group) => group.name == 'Thông tin thuốc',
    );

    if (addNumberField) {
      _customFieldStore.upsertField(
        UpsertCustomFieldCommand(
          tenantId: 'tenant-1',
          groupId: drugGroup.groupId,
          name: 'Thời gian ngưng sử dụng',
          fieldType: CustomFieldType.number,
        ),
      );
    }

    if (requireThanhPhan) {
      final thanhPhan = drugGroup.fields.firstWhere(
        (field) => field.name == 'Thành phần',
      );
      _customFieldStore.configureAttributes(
        ConfigureCustomFieldAttributesCommand(
          tenantId: 'tenant-1',
          fieldId: thanhPhan.fieldId,
          isRequired: true,
          isSearchable: false,
          isFilterable: false,
          displayOnList: false,
        ),
      );
    }
  }

  final String scenario;
  final FakeCatalogCustomFieldStore _customFieldStore;
  final List<_TenantUnit> _tenantUnits;
  final List<_ProductUnit> _productUnits;
  final List<_StoredProduct> _products;
  final Map<String, _StorePriceRule> _storeRules;
  final Map<String, List<_StorePriceRuleHistoryEntry>> _storeRuleHistory = {};
  int _nextStoreRuleHistoryId = 1;
  int _nextProductId = 11;
  int _nextProductUnitId = 1;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is CreateGuidedProductCommand) {
      return _handleCreateGuidedProduct<TResult>(
        command as CreateGuidedProductCommand,
      );
    } else if (command is CreateProductCommand) {
      return _handleCreateProduct<TResult>(command as CreateProductCommand);
    } else if (command is SetBasicStockQuantityBaseCommand) {
      final cmd = command as SetBasicStockQuantityBaseCommand;
      if (cmd.mode != 'basic') {
        throw NotBasicStockModeException();
      }
      final prod = _products.firstWhere((p) => p.id == cmd.productId);
      if (!prod.hasBaseUnit) {
        throw MissingBaseUnitException();
      }
      final previousQty = prod.stockQty ?? 0;
      prod.stockQty = cmd.quantity;
      prod.stockVersion += 1;
      prod.stockMovements = [
        ...prod.stockMovements,
        _StockMovement(
          id: 'movement-${prod.id}-${prod.stockMovements.length + 1}',
          occurredAt: DateTime.now(),
          actorDisplayName: 'Nguyễn Văn A',
          movementType: StockMovementType.initial,
          quantityBefore: previousQty,
          quantityAfter: cmd.quantity,
          delta: cmd.quantity - previousQty,
        ),
      ];
      return SetBasicStockQuantityBaseResult(
            productId: prod.id,
            quantity: cmd.quantity,
            unitName: prod.baseUnit,
            readinessSummary: _readinessSummaryFor(prod),
          )
          as TResult;
    } else if (command is AdjustBasicStockCommand) {
      final cmd = command as AdjustBasicStockCommand;
      final prod = _products.firstWhere((p) => p.id == cmd.productId);
      if (!prod.hasBaseUnit) {
        throw MissingBaseUnitException();
      }
      if (prod.stockMode.isAdvanced) {
        throw NotBasicStockModeException();
      }
      if (cmd.newQuantity < 0) {
        throw ValidationException('Số lượng tồn kho không được âm.');
      }
      final previousQty = prod.stockQty ?? 0;
      if (cmd.expectedQuantity != null && cmd.expectedQuantity != previousQty) {
        throw StaleStockQuantityException();
      }
      prod.stockQty = cmd.newQuantity;
      prod.stockVersion += 1;
      prod.stockMovements = [
        ...prod.stockMovements,
        _StockMovement(
          id: 'movement-${prod.id}-${prod.stockMovements.length + 1}',
          occurredAt: DateTime.now(),
          actorDisplayName: 'Nguyễn Văn A',
          movementType: StockMovementType.adjust,
          quantityBefore: previousQty,
          quantityAfter: cmd.newQuantity,
          delta: cmd.newQuantity - previousQty,
          reason: cmd.reason,
        ),
      ];
      return AdjustBasicStockResult(
            productId: prod.id,
            previousQuantity: previousQty,
            newQuantity: cmd.newQuantity,
            unitName: prod.baseUnit,
            readinessSummary: _readinessSummaryFor(prod),
          )
          as TResult;
    } else if (command is SetManualBasePriceCommand) {
      final cmd = command as SetManualBasePriceCommand;
      if (cmd.mode != 'manual') {
        throw NotManualBasePriceModeException();
      }
      if (cmd.basePrice < 0) {
        throw ValidationException('Giá vốn cơ sở không được âm.');
      }
      final prod = _products.firstWhere((p) => p.id == cmd.productId);
      if (!prod.hasBaseUnit) {
        throw MissingBaseUnitException();
      }
      prod.baseCost = cmd.basePrice;
      _recalculateFormulaPriceBandsForProduct(
        product: prod,
        tenantId: cmd.tenantId,
      );
      return SetManualBasePriceResult(
            productId: prod.id,
            basePrice: cmd.basePrice,
            currency: cmd.currency,
            unitName: prod.baseUnit,
            readinessSummary: _readinessSummaryFor(prod),
          )
          as TResult;
    } else if (command is SetInitialPriceBandCommand) {
      final cmd = command as SetInitialPriceBandCommand;
      final useRule = cmd.useStoreRule ?? false;
      if (useRule && (cmd.listBeforeVat == null || cmd.floorBeforeVat == null)) {
        throw MissingBasePriceException();
      }
      if (cmd.listBeforeVat != null &&
          cmd.floorBeforeVat != null &&
          cmd.floorBeforeVat! > cmd.listBeforeVat!) {
        throw FloorPriceGreaterThanListPriceException();
      }
      final prod = _products.firstWhere((p) => p.id == cmd.productId);
      if (!prod.hasBaseUnit) {
        throw MissingBaseUnitException();
      }
      prod.listBeforeVat = cmd.listBeforeVat;
      prod.floorBeforeVat = cmd.floorBeforeVat;
      prod.listAfterVat = cmd.listBeforeVat;
      prod.useStoreRule = useRule;
      return null as TResult;
    } else if (command is SetStorePriceRuleCommand) {
      return _handleSetStorePriceRule<TResult>(
        command as SetStorePriceRuleCommand,
      );
    } else if (command is ApplyStorePriceRuleCommand) {
      return _handleApplyStorePriceRule<TResult>(
        command as ApplyStorePriceRuleCommand,
      );
    } else if (command is SetProductUnitPriceBandCommand) {
      return _handleSetProductUnitPriceBand<TResult>(
        command as SetProductUnitPriceBandCommand,
      );
    }
    if (command is UpdateProductProfileCommand) {
      return _handleUpdateProductProfile<TResult>(
        command as UpdateProductProfileCommand,
      );
    }
    if (command is UpdateProductImagesCommand) {
      return _handleUpdateProductImages<TResult>(
        command as UpdateProductImagesCommand,
      );
    }
    if (command is DeactivateProductCommand) {
      return _handleDeactivateProduct<TResult>(
        command as DeactivateProductCommand,
      );
    }
    if (command is ReactivateProductCommand) {
      return _handleReactivateProduct<TResult>(
        command as ReactivateProductCommand,
      );
    }
    if (command is DeleteProductCommand) {
      return _handleDeleteProduct<TResult>(
        command as DeleteProductCommand,
      );
    }
    if (command is RestoreProductCommand) {
      return _handleRestoreProduct<TResult>(
        command as RestoreProductCommand,
      );
    }
    if (command is RequestProductMaintenanceImageUploadCommand) {
      return _handleRequestMaintenanceUpload<TResult>(
        command as RequestProductMaintenanceImageUploadCommand,
      );
    }
    if (command is RequestProductImageUploadCommand) {
      return _handleRequestUpload<TResult>(
        command as RequestProductImageUploadCommand,
      );
    }
    if (command is SetProductBaseUnitCommand) {
      return _handleSetProductBaseUnit<TResult>(
        command as SetProductBaseUnitCommand,
      );
    }
    if (command is AddProductConversionUnitCommand) {
      return _handleAddProductConversionUnit<TResult>(
        command as AddProductConversionUnitCommand,
      );
    }
    if (command is DeactivateProductConversionUnitCommand) {
      return _handleDeactivateProductConversionUnit<TResult>(
        command as DeactivateProductConversionUnitCommand,
      );
    }
    if (command is ReactivateProductConversionUnitCommand) {
      return _handleReactivateProductConversionUnit<TResult>(
        command as ReactivateProductConversionUnitCommand,
      );
    }
    if (command is DeleteProductConversionUnitCommand) {
      return _handleDeleteProductConversionUnit<TResult>(
        command as DeleteProductConversionUnitCommand,
      );
    }
    if (command is InitializeCustomFieldTemplateCommand) {
      return _customFieldStore.initializeTemplate(
            command as InitializeCustomFieldTemplateCommand,
          )
          as TResult;
    }
    if (command is UpsertCustomFieldGroupCommand) {
      return _customFieldStore.upsertGroup(
            command as UpsertCustomFieldGroupCommand,
          )
          as TResult;
    }
    if (command is ReorderCustomFieldGroupsCommand) {
      _customFieldStore.reorderGroups(
        command as ReorderCustomFieldGroupsCommand,
      );
      return null as TResult;
    }
    if (command is UpsertCustomFieldCommand) {
      return _customFieldStore.upsertField(command as UpsertCustomFieldCommand) as TResult;
    }
    if (command is ConfigureCustomFieldAttributesCommand) {
      return _customFieldStore.configureAttributes(
            command as ConfigureCustomFieldAttributesCommand,
          )
          as TResult;
    }
    if (command is ReorderCustomFieldsCommand) {
      _customFieldStore.reorderFields(command as ReorderCustomFieldsCommand);
      return null as TResult;
    }
    if (command is UpsertCustomFieldValuesCommand) {
      return _handleUpsertCustomFieldValues<TResult>(
        command as UpsertCustomFieldValuesCommand,
      );
    }
    throw UnimplementedError('Unexpected command: ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is CheckDuplicateProductCodeQuery) {
      return _handleCheckDuplicate<TResult>(
        query as CheckDuplicateProductCodeQuery,
      );
    }
    if (query is GetProductReadinessQuery) {
      return _handleGetProductReadiness<TResult>(
        query as GetProductReadinessQuery,
      );
    }
    if (query is SearchProductsQuery) {
      return _handleSearchProducts<TResult>(query as SearchProductsQuery);
    }
    if (query is ScanBarcodeQuery) {
      return _handleScanBarcode<TResult>(query as ScanBarcodeQuery);
    }
    if (query is GetProductControlCenterQuery) {
      return _handleGetProductControlCenter<TResult>(
        query as GetProductControlCenterQuery,
      );
    }
    if (query is CheckProductDeletionEligibilityQuery) {
      return _handleCheckProductDeletionEligibility<TResult>(
        query as CheckProductDeletionEligibilityQuery,
      );
    }
    if (query is ListTenantMeasurementUnitsQuery) {
      return _handleListTenantUnits<TResult>(
        query as ListTenantMeasurementUnitsQuery,
      );
    }
    if (query is CheckDuplicateMeasurementUnitNameQuery) {
      return _handleCheckDuplicateUnitName<TResult>(
        query as CheckDuplicateMeasurementUnitNameQuery,
      );
    }
    if (query is ListProductUnitsQuery) {
      return _handleListProductUnits<TResult>(query as ListProductUnitsQuery);
    }
    if (query is GetProductStockHistoryQuery) {
      return _handleGetProductStockHistory<TResult>(
        query as GetProductStockHistoryQuery,
      );
    }
    if (query is GetStorePriceRuleQuery) {
      return _handleGetStorePriceRule<TResult>(query as GetStorePriceRuleQuery);
    }
    if (query is GetStorePriceRuleChangeHistoryQuery) {
      return _handleGetStorePriceRuleChangeHistory<TResult>(
        query as GetStorePriceRuleChangeHistoryQuery,
      );
    }
    if (query is SuggestProductUnitPriceQuery) {
      return _handleSuggestProductUnitPrice<TResult>(
        query as SuggestProductUnitPriceQuery,
      );
    }
    if (query is ListProductUnitPriceBandsQuery) {
      return _handleListProductUnitPriceBands<TResult>(
        query as ListProductUnitPriceBandsQuery,
      );
    }
    if (query is GetProductPriceBandSnapshotQuery) {
      return _handleGetProductPriceBandSnapshot<TResult>(
        query as GetProductPriceBandSnapshotQuery,
      );
    }
    if (query is GetProductChangeHistoryQuery) {
      return _handleGetProductChangeHistory<TResult>(
        query as GetProductChangeHistoryQuery,
      );
    }
    if (query is ListCustomFieldConfigQuery) {
      return _customFieldStore.listConfig(
            (query as ListCustomFieldConfigQuery).tenantId,
          )
          as TResult;
    }
    if (query is GetProductCustomFieldValuesQuery) {
      final customFieldQuery = query as GetProductCustomFieldValuesQuery;
      return _customFieldStore.getValues(
            tenantId: customFieldQuery.tenantId,
            productId: customFieldQuery.productId,
            includeInactiveValues: customFieldQuery.includeInactiveValues,
          )
          as TResult;
    }
    if (query is ListCustomFieldFilterOptionsQuery) {
      _assertCatalogReadPermission();
      final filterQuery = query as ListCustomFieldFilterOptionsQuery;
      return _customFieldStore.listFilterOptions(
            tenantId: filterQuery.tenantId,
            maxOptionsPerField: filterQuery.maxOptionsPerField,
          )
          as TResult;
    }
    if (query is GetProductCustomFieldSnapshotQuery) {
      _assertCatalogDetailPermission();
      final snapshotQuery = query as GetProductCustomFieldSnapshotQuery;
      return _customFieldStore.getSnapshot(
            tenantId: snapshotQuery.tenantId,
            productIds: snapshotQuery.productIds,
            includeInactiveValues: snapshotQuery.includeInactiveValues,
          )
          as TResult;
    }
    throw UnimplementedError('Unexpected query: ${query.runtimeType}');
  }

  TResult _handleUpsertCustomFieldValues<TResult>(
    UpsertCustomFieldValuesCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    _customFieldStore.upsertValues(command);
    return UpsertCustomFieldValuesResult(
          productId: product.id,
          values: _customFieldStore.getValues(
            tenantId: command.tenantId,
            productId: product.id,
          ),
          readinessSummary: _readinessSummaryFor(product),
        )
        as TResult;
  }

  TResult _handleRequestMaintenanceUpload<TResult>(
    RequestProductMaintenanceImageUploadCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    if (_isSoftDeletedForMaintenance(product)) {
      throw ApplicationException('Product is soft-deleted and cannot be updated.');
    }
    if (scenario == FakeCatalogScenario.scnContractE07U01Fr02_04) {
      throw ValidationException('Unsupported image content type.');
    }
    if (!_isSupportedImageContentType(command.contentType)) {
      throw ValidationException('Unsupported image content type.');
    }

    final slotId = 'slot-maintenance-${command.productId}-${product.version}';
    return ProductImageUploadSlotDto(
          slotId: slotId,
          storageKey: '${command.tenantId}/staging/$slotId/original.jpeg',
          signedUploadUrl: 'https://storage.fake/upload/$slotId',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        )
        as TResult;
  }

  TResult _handleUpdateProductProfile<TResult>(
    UpdateProductProfileCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    _ensureMaintenanceAllowed(product, command.expectedVersion);

    final productName = command.productName.trim();
    if (productName.isEmpty) {
      throw ValidationException('Product name is required.');
    }
    final sku = _normalizeSku(_optionalText(command.sku) ?? '');
    final barcode = _optionalText(command.barcode) ?? '';
    _ensureUniqueSku(product, sku);
    _ensureUniqueBarcode(product, barcode);

    product.name = productName;
    product.tradeName = _optionalText(command.commercialName);
    product.sku = sku;
    product.barcode = barcode;
    product.description = _optionalText(command.description);
    product.notes = _optionalText(command.note);
    _markUpdated(product);

    return UpdateProductProfileResult(
          productId: product.id,
          profile: _toProfileSummary(product),
          readinessSummary: _readinessSummaryFor(product),
          version: product.version,
        )
        as TResult;
  }

  TResult _handleUpdateProductImages<TResult>(
    UpdateProductImagesCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    _ensureMaintenanceAllowed(product, command.expectedVersion);

    final images = _normalizeImageMutationInputs(command.images);
    product.imageDetails = images;
    product.images = images.map((image) => image.url ?? image.storageKey).toList(growable: false);
    _markUpdated(product);

    return UpdateProductImagesResult(
          productId: product.id,
          images: images,
          primaryImageUrl: _primaryImageUrl(images),
          readinessSummary: _readinessSummaryFor(product),
          version: product.version,
        )
        as TResult;
  }

  TResult _handleDeactivateProduct<TResult>(DeactivateProductCommand command) {
    if (scenario == FakeCatalogScenario.scnContractE07U02Fr01_03) {
      throw ApplicationException('Permission denied');
    }

    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    _ensureStatusChangeAllowed(product, command.expectedVersion);
    if (product.businessStatus == ProductBusinessStatus.inactive) {
      throw ValidationException('Product is already inactive.');
    }

    final warnings = _businessStatusWarningsFor(product);
    if (warnings.isNotEmpty && !command.confirmAcknowledgeWarnings) {
      throw ProductBusinessStatusWarningsRequireAcknowledgmentException(
        warnings: warnings,
      );
    }

    return _changeProductStatus<TResult>(
      product: product,
      nextStatus: ProductBusinessStatus.inactive,
      actorId: command.actorId,
      reason: command.reason,
      warnings: warnings,
    );
  }

  TResult _handleReactivateProduct<TResult>(ReactivateProductCommand command) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    if (scenario == FakeCatalogScenario.scnContractE07U02Fr02_02 && product.id == 'product-4') {
      product.businessStatus = ProductBusinessStatus.inactive;
    }
    _ensureStatusChangeAllowed(product, command.expectedVersion);
    if (product.businessStatus == ProductBusinessStatus.active) {
      throw ValidationException('Product is already active.');
    }

    return _changeProductStatus<TResult>(
      product: product,
      nextStatus: ProductBusinessStatus.active,
      actorId: command.actorId,
      reason: command.reason,
    );
  }

  TResult _handleDeleteProduct<TResult>(DeleteProductCommand command) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    _ensureSoftDeleteVersion(product, command.expectedVersion);
    if (product.isSoftDeleted) {
      throw ValidationException('Product is already soft-deleted.');
    }

    final eligibility = _deletionEligibilityFor(product);
    if (!eligibility.canDelete) {
      throw ValidationException('Product cannot be deleted because dependencies are blocking it.');
    }
    if (eligibility.warnings.isNotEmpty && !command.confirmAcknowledgeWarnings) {
      throw ValidationException('Product deletion warnings require acknowledgment.');
    }

    product.businessStatus = ProductBusinessStatus.softDeleted;
    _markUpdated(product);

    final historyEntry = ProductChangeHistoryEntryDto(
      id: 'history-${product.id}-soft-delete-${product.version}',
      occurredAt: product.updatedAt,
      actorDisplayName: command.actorId,
      changeType: ProductChangeHistoryAction.softDeleted,
      summary: 'Xóa mềm sản phẩm',
      valueBefore: 'false',
      valueAfter: 'true',
    );
    product.statusHistory = [
      historyEntry,
      ...product.statusHistory,
    ];

    return ChangeProductSoftDeleteResult(
          productId: product.id,
          businessStatus: product.businessStatus,
          readinessSummary: _readinessSummaryFor(product),
          version: product.version,
          reason: _optionalText(command.reason),
          issues: eligibility.issues,
          historyEntry: historyEntry,
        )
        as TResult;
  }

  TResult _handleRestoreProduct<TResult>(RestoreProductCommand command) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    _prepareSoftDeletedRestoreScenario(product);
    _ensureSoftDeleteVersion(product, command.expectedVersion);
    if (!product.isSoftDeleted) {
      throw ValidationException('Only soft-deleted products can be restored.');
    }
    _ensureUniqueActiveSku(product, product.sku);
    _ensureUniqueActiveBarcode(product, product.barcode);

    product.businessStatus = ProductBusinessStatus.inactive;
    _markUpdated(product);

    final historyEntry = ProductChangeHistoryEntryDto(
      id: 'history-${product.id}-restore-${product.version}',
      occurredAt: product.updatedAt,
      actorDisplayName: command.actorId,
      changeType: ProductChangeHistoryAction.restored,
      summary: 'Khôi phục sản phẩm đã xóa mềm',
      valueBefore: 'true',
      valueAfter: 'false',
    );
    product.statusHistory = [
      historyEntry,
      ...product.statusHistory,
    ];

    return ChangeProductSoftDeleteResult(
          productId: product.id,
          businessStatus: product.businessStatus,
          readinessSummary: _readinessSummaryFor(product),
          version: product.version,
          reason: _optionalText(command.reason),
          historyEntry: historyEntry,
        )
        as TResult;
  }

  TResult _handleCheckProductDeletionEligibility<TResult>(
    CheckProductDeletionEligibilityQuery query,
  ) {
    final product = _findProduct(query.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    return _deletionEligibilityFor(product) as TResult;
  }

  ProductDeletionEligibilityDto _deletionEligibilityFor(_StoredProduct product) {
    final issues = <ProductDeletionIssueDto>[];
    String? suggestedActionId;

    if (scenario == FakeCatalogScenario.scnContractE07U03Fr01_02 && product.id == 'product-4') {
      issues.add(
        const ProductDeletionIssueDto(
          code: ProductDeletionIssueCode.openTransaction,
          message: 'Sản phẩm đang nằm trong giao dịch mở.',
          severity: ProductDeletionIssueSeverity.blocker,
        ),
      );
    }

    if (scenario == FakeCatalogScenario.scnContractE07U03Fr01_03 && product.id == 'product-1') {
      issues.add(
        const ProductDeletionIssueDto(
          code: ProductDeletionIssueCode.hasHistoricalTransactions,
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

  void _ensureSoftDeleteVersion(_StoredProduct product, int? expectedVersion) {
    if (expectedVersion != null && expectedVersion != product.version) {
      throw StaleProductVersionException(
        expectedVersion: expectedVersion,
        currentVersion: product.version,
      );
    }
  }

  void _prepareSoftDeletedRestoreScenario(_StoredProduct product) {
    if (product.id != 'product-7') {
      return;
    }
    if (scenario == FakeCatalogScenario.scnContractE07U03Fr03_02) {
      product.businessStatus = ProductBusinessStatus.softDeleted;
      product.sku = 'SP0001';
    } else if (scenario == FakeCatalogScenario.scnContractE07U03Fr03_03) {
      product.businessStatus = ProductBusinessStatus.softDeleted;
      product.barcode = '8930000000001';
    }
  }

  void _ensureStatusChangeAllowed(_StoredProduct product, int? expectedVersion) {
    if (_isSoftDeletedForStatusChange(product)) {
      throw ApplicationException(
        'Product is soft-deleted and cannot change business status.',
      );
    }
    if (expectedVersion != null && expectedVersion != product.version) {
      throw StaleProductVersionException(
        expectedVersion: expectedVersion,
        currentVersion: product.version,
      );
    }
  }

  bool _isSoftDeletedForStatusChange(_StoredProduct product) {
    return product.isSoftDeleted ||
        (scenario == FakeCatalogScenario.scnContractE07U02Fr02_03 && product.id == 'product-7');
  }

  List<ProductBusinessStatusWarningDto> _businessStatusWarningsFor(
    _StoredProduct product,
  ) {
    if (scenario == FakeCatalogScenario.scnContractE07U02Fr01_02 &&
        product.stockQty != null &&
        product.stockQty! > 0) {
      return const [
        ProductBusinessStatusWarningDto(
          code: ProductBusinessStatusWarningCode.hasStock,
          message: 'Sản phẩm vẫn còn tồn kho hiện hành.',
        ),
      ];
    }
    return const [];
  }

  TResult _changeProductStatus<TResult>({
    required _StoredProduct product,
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
    product.statusHistory = [
      historyEntry,
      ...product.statusHistory,
    ];

    return ChangeProductBusinessStatusResult(
          productId: product.id,
          previousStatus: previousStatus,
          currentStatus: nextStatus,
          readinessSummary: _readinessSummaryFor(product),
          version: product.version,
          reason: _optionalText(reason),
          warnings: warnings,
          historyEntry: historyEntry,
        )
        as TResult;
  }

  void _ensureMaintenanceAllowed(_StoredProduct product, int? expectedVersion) {
    if (_isSoftDeletedForMaintenance(product)) {
      throw ApplicationException('Product is soft-deleted and cannot be updated.');
    }
    if (expectedVersion != null && expectedVersion != product.version) {
      throw StaleProductVersionException(
        expectedVersion: expectedVersion,
        currentVersion: product.version,
      );
    }
  }

  bool _isSoftDeletedForMaintenance(_StoredProduct product) {
    return product.isSoftDeleted ||
        (scenario == FakeCatalogScenario.scnContractE07U01Fr01_04 && product.id == 'product-7');
  }

  void _ensureUniqueSku(_StoredProduct target, String sku) {
    final normalized = _normalizeSku(sku);
    if (normalized.isEmpty) {
      return;
    }
    for (final product in _products) {
      if (product.id != target.id &&
          !product.isSoftDeleted &&
          _normalizeSku(product.sku) == normalized) {
        throw DuplicateSkuException(
          sku: sku,
          existingProductId: product.id,
          existingProductName: product.name,
        );
      }
    }
  }

  void _ensureUniqueBarcode(_StoredProduct target, String barcode) {
    if (barcode.isEmpty) {
      return;
    }
    for (final product in _products) {
      if (product.id != target.id && !product.isSoftDeleted && product.barcode == barcode) {
        throw DuplicateBarcodeException(
          barcode: barcode,
          existingProductId: product.id,
          existingProductName: product.name,
        );
      }
    }
  }

  void _ensureUniqueActiveSku(_StoredProduct target, String sku) {
    final normalized = _normalizeSku(sku);
    if (normalized.isEmpty) {
      return;
    }
    for (final product in _products) {
      if (product.id != target.id &&
          !product.isSoftDeleted &&
          _normalizeSku(product.sku) == normalized) {
        throw DuplicateSkuException(
          sku: sku,
          existingProductId: product.id,
          existingProductName: product.name,
        );
      }
    }
  }

  void _ensureUniqueActiveBarcode(_StoredProduct target, String barcode) {
    if (barcode.isEmpty) {
      return;
    }
    for (final product in _products) {
      if (product.id != target.id && !product.isSoftDeleted && product.barcode == barcode) {
        throw DuplicateBarcodeException(
          barcode: barcode,
          existingProductId: product.id,
          existingProductName: product.name,
        );
      }
    }
  }

  List<ProductImageDto> _normalizeImageMutationInputs(
    List<ProductImageMutationInput> inputs,
  ) {
    if (inputs.isEmpty) {
      return const [];
    }

    final sorted = [...inputs]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final hasPrimary = sorted.any((image) => image.isPrimary);
    return [
      for (var index = 0; index < sorted.length; index++)
        ProductImageDto(
          imageId: sorted[index].imageId ?? 'image-${index + 1}',
          storageKey: sorted[index].storageKey,
          url: sorted[index].url,
          isPrimary: hasPrimary ? sorted[index].isPrimary : index == 0,
          sortOrder: index,
        ),
    ];
  }

  String? _primaryImageUrl(List<ProductImageDto> images) {
    for (final image in images) {
      if (image.isPrimary) {
        return image.url ?? image.storageKey;
      }
    }
    return null;
  }

  ProductProfileSummaryDto _toProfileSummary(_StoredProduct product) {
    return ProductProfileSummaryDto(
      productId: product.id,
      name: product.name,
      tradeName: product.tradeName,
      sku: product.sku.isEmpty ? null : product.sku,
      barcode: product.barcode.isEmpty ? null : product.barcode,
      businessStatus: product.businessStatus,
      primaryImageUrl: product.images.isNotEmpty ? product.images.first : null,
      images: product.images,
      description: product.description,
      note: product.notes,
    );
  }

  void _markUpdated(_StoredProduct product) {
    product.version += 1;
    product.updatedAt = DateTime.now().toUtc();
  }

  bool _isSupportedImageContentType(String contentType) {
    return switch (contentType) {
      'image/jpeg' || 'image/png' || 'image/webp' => true,
      _ => false,
    };
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  /// Matches Postgres `catalog._normalize_product_sku` (trim + uppercase).
  String _normalizeSku(String sku) {
    final normalized = sku.trim().toUpperCase();
    return normalized;
  }

  TResult _handleRequestUpload<TResult>(
    RequestProductImageUploadCommand command,
  ) {
    switch (scenario) {
      case FakeCatalogScenario.guidedCreatePermissionDenied:
      case FakeCatalogScenario.readinessPermissionDenied:
        throw ApplicationException('Permission denied');
      case FakeCatalogScenario.guidedCreateUploadInvalidType:
        throw ValidationException('Unsupported image content type.');
      case FakeCatalogScenario.guidedCreateUploadSlotOk:
      default:
        final slotId = 'slot-$_nextProductId';
        return ProductImageUploadSlotDto(
              slotId: slotId,
              storageKey: '${command.tenantId}/staging/$slotId/original.jpeg',
              signedUploadUrl: 'https://storage.fake/upload/$slotId',
              expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
            )
            as TResult;
    }
  }

  TResult _handleCreateGuidedProduct<TResult>(CreateGuidedProductCommand command) {
    final createResult = _handleCreateProduct<CreateProductResult>(
      CreateProductCommand(
        id: command.id,
        tenantId: command.tenantId,
        actorId: command.actorId,
        productName: command.productName,
        commercialName: command.commercialName,
        sku: command.sku,
        barcode: command.barcode,
        images: command.images,
      ),
    );
    final product = _products.firstWhere((item) => item.id == createResult.productId);
    final selection = command.baseUnit;
    product.baseUnit = switch (selection) {
      ExistingTenantUnit(:final unitId) =>
        _tenantUnits.firstWhere((unit) => unit.id == unitId).name,
      NewTenantUnit(:final name) => () {
        final normalized = _normalizeUnitName(name);
        final alreadyExists = _tenantUnits.any(
          (unit) => _normalizeUnitName(unit.name) == normalized,
        );
        if (!alreadyExists) {
          _tenantUnits.add(
            _TenantUnit(id: 'unit-new-${_tenantUnits.length + 1}', name: name),
          );
        }
        return name;
      }(),
      null => '',
    };
    product.stockQty = command.basicStockQuantityBase;
    product.baseCost = command.basePrice;
    product.listBeforeVat = command.listBeforeVat;
    product.floorBeforeVat = command.floorBeforeVat;
    product.listAfterVat = command.listBeforeVat;
    return CreateGuidedProductResult(
          productId: product.id,
          readinessSummary: _readinessSummaryFor(product),
        )
        as TResult;
  }

  TResult _handleCreateProduct<TResult>(CreateProductCommand command) {
    switch (scenario) {
      case FakeCatalogScenario.guidedCreatePermissionDenied:
      case FakeCatalogScenario.readinessPermissionDenied:
        throw ApplicationException('Permission denied');
      case FakeCatalogScenario.guidedCreateDupSku:
        throw DuplicateSkuException(
          sku: command.sku ?? 'SKU-001',
          existingProductId: 'product-existing-1',
          existingProductName: 'Existing Product',
        );
      case FakeCatalogScenario.guidedCreateDupBarcode:
        throw DuplicateBarcodeException(
          barcode: command.barcode ?? '8901234567890',
          existingProductId: 'product-existing-1',
          existingProductName: 'Existing Product',
        );
      case FakeCatalogScenario.guidedCreateDupReference:
        throw DuplicateReferenceIdException(
          referenceId: command.referenceId ?? 'SP-0001',
          existingProductId: 'product-existing-1',
          existingProductName: 'Existing Product',
        );
      case FakeCatalogScenario.guidedCreateMissingName:
        throw ValidationException('Product name is required.');
      case FakeCatalogScenario.guidedCreateNoImages:
        return _persistCreate(command) as TResult;
      case FakeCatalogScenario.readinessReadyToSell:
        return _persistCreate(
              command,
              hasStock: true,
              hasBasePrice: true,
              hasPriceBand: true,
            )
            as TResult;
      case FakeCatalogScenario.readinessManyBlockers:
        return _persistCreate(
              command,
              hasImages: false,
            )
            as TResult;
      case FakeCatalogScenario.readinessAdvancedStockPending:
        return _persistCreate(
              command,
              stockMode: FakeProductReadinessBuilder.stockModeAdvanced,
            )
            as TResult;
      case FakeCatalogScenario.readinessCostingBasePricePending:
        return _persistCreate(
              command,
              basePriceMode: FakeProductReadinessBuilder.basePriceModeCosting,
            )
            as TResult;
      case FakeCatalogScenario.readinessMissingCustomFields:
        return _persistCreate(
              command,
              hasRequiredCustomFields: false,
            )
            as TResult;
      case FakeCatalogScenario.readinessNoPricePermission:
        return _persistCreate(
              command,
              hasStock: true,
              hasBasePrice: true,
              pricePermissionDenied: true,
            )
            as TResult;
      case FakeCatalogScenario.readinessRefreshAfterUnit:
        return _persistCreate(
              command,
              hasBasePrice: true,
            )
            as TResult;
      case FakeCatalogScenario.guidedCreateOk:
      default:
        return _persistCreate(command) as TResult;
    }
  }

  CreateProductResult _persistCreate(
    CreateProductCommand command, {
    bool hasImages = true,
    bool hasStock = false,
    bool hasBasePrice = false,
    bool hasPriceBand = false,
    bool hasRequiredCustomFields = true,
    StockMode stockMode = FakeProductReadinessBuilder.stockModeBasic,
    BasePriceMode basePriceMode = FakeProductReadinessBuilder.basePriceModeManual,
    bool pricePermissionDenied = false,
  }) {
    final productId = 'product-new-${_nextProductId++}';
    final referenceId = _resolveCreateReferenceId(command, productId);
    final images = hasImages ? command.images.map((img) => img.storageKey).toList() : <String>[];

    final product = _StoredProduct(
      id: productId,
      referenceId: referenceId,
      name: command.productName,
      tradeName: command.commercialName,
      sku: _normalizeSku(command.sku ?? ''),
      barcode: command.barcode ?? '',
      baseUnit: command.baseUnitName ?? '',
      images: images,
      stockQty: hasStock ? 0 : null,
      baseCost: hasBasePrice ? 0 : null,
      listBeforeVat: hasPriceBand ? 1 : null,
      floorBeforeVat: hasPriceBand ? 1 : null,
      listAfterVat: hasPriceBand ? 1 : null,
      notes: command.note,
      hasRequiredCustomFields: hasRequiredCustomFields,
      stockMode: stockMode,
      basePriceMode: basePriceMode,
      pricePermissionDenied: pricePermissionDenied,
    );

    _ensureUniqueSku(product, product.sku);
    _ensureUniqueBarcode(product, product.barcode);
    _products.add(product);

    final view = _buildReadinessView(product);
    return CreateProductResult(
      productId: productId,
      readinessSummary: view.readinessSummary,
    );
  }

  String _resolveCreateReferenceId(CreateProductCommand command, String productId) {
    final explicit = command.referenceId?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final suffix = productId.hashCode.abs().toRadixString(16).padLeft(12, '0').substring(0, 12);
    return ProductReferenceId.fromProductId(
      ProductId('00000000-0000-4000-8000-$suffix'),
    ).value;
  }

  TResult _handleGetProductReadiness<TResult>(
    GetProductReadinessQuery query,
  ) {
    if (scenario == FakeCatalogScenario.readinessPermissionDenied) {
      throw ApplicationException('Permission denied');
    }

    final product = _findProduct(query.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }

    return _buildReadinessView(product) as TResult;
  }

  TResult _handleSearchProducts<TResult>(SearchProductsQuery query) {
    _assertCatalogReadPermission();
    if (scenario == FakeCatalogScenario.searchEmpty) {
      return const ProductSearchResultDto(items: [], totalCount: 0) as TResult;
    }

    final filtered = _visibleProducts(query.criteria);
    final items = filtered.map(_toListItemDto).toList(growable: false);

    final start = query.offset.clamp(0, items.length);
    final end = (query.offset + query.limit).clamp(0, items.length);
    final page = items.sublist(start, end);

    return ProductSearchResultDto(
          items: page,
          totalCount: items.length,
        )
        as TResult;
  }

  TResult _handleScanBarcode<TResult>(ScanBarcodeQuery query) {
    if (scenario == FakeCatalogScenario.barcodeNotFound) {
      return null as TResult;
    }

    final barcode = query.barcode.trim();
    for (final product in _products) {
      if (product.isSoftDeleted) {
        continue;
      }
      if (product.barcode == barcode) {
        return _toListItemDto(product) as TResult;
      }
    }

    if (scenario == FakeCatalogScenario.barcodeExactMatch) {
      return null as TResult;
    }

    return null as TResult;
  }

  TResult _handleGetProductControlCenter<TResult>(
    GetProductControlCenterQuery query,
  ) {
    if (scenario == FakeCatalogScenario.readinessPermissionDenied) {
      throw ApplicationException('Permission denied');
    }

    final product = _resolveControlCenterProduct(query.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }

    return _toControlCenterDto(product) as TResult;
  }

  TResult _handleGetProductStockHistory<TResult>(
    GetProductStockHistoryQuery query,
  ) {
    final product = _findProduct(query.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    if (product.stockMode.isAdvanced) {
      final rows = product.stockMovements
          .take(query.limit)
          .map(
            (movement) => ProductStockMovementDto(
              id: movement.id,
              occurredAt: movement.occurredAt,
              actorDisplayName: movement.actorDisplayName,
              movementType: movement.movementType,
              quantityBefore: movement.quantityBefore,
              quantityAfter: movement.quantityAfter,
              delta: movement.delta,
              reason: movement.reason,
            ),
          )
          .toList(growable: false);
      return ProductStockHistoryDto(
            productId: product.id,
            unitName: product.baseUnit,
            isHistoricalBasicOnly: true,
            movements: rows,
          )
          as TResult;
    }
    final rows = product.stockMovements
        .take(query.limit)
        .map(
          (movement) => ProductStockMovementDto(
            id: movement.id,
            occurredAt: movement.occurredAt,
            actorDisplayName: movement.actorDisplayName,
            movementType: movement.movementType,
            quantityBefore: movement.quantityBefore,
            quantityAfter: movement.quantityAfter,
            delta: movement.delta,
            reason: movement.reason,
          ),
        )
        .toList(growable: false);
    return ProductStockHistoryDto(
          productId: product.id,
          unitName: product.baseUnit,
          isHistoricalBasicOnly: true,
          movements: rows,
        )
        as TResult;
  }

  _StoredProduct? _resolveControlCenterProduct(String productId) {
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

  ProductControlCenterDto _toControlCenterDto(_StoredProduct product) {
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

    return FakeCatalogProductBuilder.toControlCenter(
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
      priceBandSourceType: product.priceBandSourceType,
      storePriceRuleName: product.storePriceRuleName,
      isCustomOverride: product.isCustomOverride,
      hasRequiredCustomFields: _productHasRequiredCustomFields(product),
      stockMode: product.stockMode,
      basePriceMode: product.basePriceMode,
      pricePermissionDenied: product.pricePermissionDenied,
      customFieldGroupCards: customFieldCards,
      changeHistoryPreview: history,
    );
  }

  List<_StoredProduct> _visibleProducts(ProductSearchCriteria criteria) {
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
      final byStatus = statusRank(a.businessStatus).compareTo(
        statusRank(b.businessStatus),
      );
      if (byStatus != 0) {
        return byStatus;
      }
      if (useRelevance) {
        final byRank = _approximateRelevanceRank(b, keyword!).compareTo(
          _approximateRelevanceRank(a, keyword),
        );
        if (byRank != 0) {
          return byRank;
        }
      }
      final byUpdated = b.updatedAt.compareTo(a.updatedAt);
      if (byUpdated != 0) {
        return byUpdated;
      }
      return a.name.compareTo(b.name);
    });
  }

  bool _matchesKeyword(_StoredProduct product, String? keyword) {
    if (keyword == null) {
      return true;
    }
    final foldedKeyword = SearchKeywordNormalizer.foldForSearch(keyword);
    final fields = [
      product.name,
      product.tradeName ?? '',
      product.sku,
      product.barcode,
    ];
    for (final field in fields) {
      final foldedField = SearchKeywordNormalizer.foldForSearch(field);
      if (foldedField.contains(foldedKeyword) || field == keyword) {
        return true;
      }
    }
    return _customFieldStore.matchesSearchKeyword(product.id, keyword);
  }

  /// Approximate FTS rank for fake/tests (name > tradeName > sku > barcode > CF).
  int _approximateRelevanceRank(_StoredProduct product, String keyword) {
    final foldedKeyword = SearchKeywordNormalizer.foldForSearch(keyword);
    final name = SearchKeywordNormalizer.foldForSearch(product.name);
    final trade = SearchKeywordNormalizer.foldForSearch(product.tradeName ?? '');
    final sku = SearchKeywordNormalizer.foldForSearch(product.sku);
    final barcode = SearchKeywordNormalizer.foldForSearch(product.barcode);
    if (name.startsWith(foldedKeyword)) {
      return 500;
    }
    if (name.contains(foldedKeyword)) {
      return 400;
    }
    if (trade.contains(foldedKeyword)) {
      return 300;
    }
    if (sku == foldedKeyword || sku.startsWith(foldedKeyword)) {
      return 250;
    }
    if (barcode == foldedKeyword || barcode.contains(foldedKeyword)) {
      return 200;
    }
    if (_customFieldStore.matchesSearchKeyword(product.id, keyword)) {
      return 100;
    }
    return 0;
  }

  void _assertCatalogReadPermission() {
    if (scenario == FakeCatalogScenario.customFieldSearchPermissionDenied ||
        scenario == FakeCatalogScenario.scnContractE06U04PermissionDenied) {
      throw ApplicationException('Permission denied');
    }
  }

  void _assertCatalogDetailPermission() {
    if (scenario == FakeCatalogScenario.customFieldSearchPermissionDenied) {
      throw ApplicationException('Permission denied');
    }
  }

  void _assertViewHistoryPermission() {
    if (scenario == FakeCatalogScenario.scnContractE07U04Fr03_01 ||
        scenario == FakeCatalogScenario.scnContractE07U04PermissionDenied) {
      throw ApplicationException('Permission denied');
    }
  }

  bool _matchesReadinessFilter(
    _StoredProduct product,
    ProductReadinessFilter? filter,
  ) {
    if (filter == null) {
      return true;
    }
    final summary = _readinessSummaryFor(product);
    return switch (filter) {
      ProductReadinessFilter.readyToSell => summary.status == ReadinessStatus.readyToSell,
      ProductReadinessFilter.incomplete => summary.status == ReadinessStatus.incomplete,
    };
  }

  ProductListItemDto _toListItemDto(_StoredProduct product) {
    final summary = _readinessSummaryFor(product);
    return FakeCatalogProductBuilder.toListItem(
      id: product.id,
      name: product.name,
      tradeName: product.tradeName,
      sku: product.sku,
      barcode: product.barcode,
      primaryImageUrl: product.images.isNotEmpty ? product.images.first : null,
      businessStatus: product.businessStatus,
      readinessSummary: summary,
      listBeforeVat: product.listBeforeVat,
      floorBeforeVat: product.floorBeforeVat,
      baseUnit: product.baseUnit,
      stockQuantity: product.stockQty,
      updatedAt: product.updatedAt,
      customFieldValues: _customFieldStore.listDisplayValuesForProduct(product.id),
    );
  }

  ReadinessSummaryDto _readinessSummaryFor(_StoredProduct product) {
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

  _StoredProduct? _findProduct(String productId) {
    for (final product in _products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  bool _productHasRequiredCustomFields(_StoredProduct product) {
    return product.hasRequiredCustomFields && _customFieldStore.hasRequiredValues(product.id);
  }

  ProductReadinessViewDto _buildReadinessView(_StoredProduct product) {
    return FakeProductReadinessBuilder.build(
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
      pricePermissionDenied: product.pricePermissionDenied,
    );
  }

  String _normalizeUnitName(String name) => name.trim().toLowerCase();

  TResult _handleListTenantUnits<TResult>(
    ListTenantMeasurementUnitsQuery query,
  ) {
    final keyword = query.keyword?.trim().toLowerCase();
    final units = _tenantUnits
        .where((unit) {
          if (keyword == null || keyword.isEmpty) {
            return true;
          }
          return unit.name.toLowerCase().contains(keyword);
        })
        .take(query.limit);

    return units
            .map(
              (unit) => TenantMeasurementUnitDto(
                id: unit.id,
                name: unit.name,
                isActive: unit.isActive,
              ),
            )
            .toList(growable: false)
        as TResult;
  }

  TResult _handleCheckDuplicateUnitName<TResult>(
    CheckDuplicateMeasurementUnitNameQuery query,
  ) {
    if (scenario == FakeCatalogScenario.setBaseUnitDuplicate) {
      return true as TResult;
    }

    final normalized = _normalizeUnitName(query.name);
    final isDuplicate = _tenantUnits.any(
      (unit) => _normalizeUnitName(unit.name) == normalized,
    );
    return isDuplicate as TResult;
  }

  TResult _handleSetProductBaseUnit<TResult>(
    SetProductBaseUnitCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    if (product.hasBaseUnit) {
      throw ValidationException(
        'Product already has a base unit; change base unit is out of scope.',
      );
    }

    final selection = command.selection;
    late final String unitName;

    if (selection is ExistingTenantUnit) {
      _TenantUnit? unit;
      for (final item in _tenantUnits) {
        if (item.id == selection.unitId) {
          unit = item;
          break;
        }
      }
      if (unit == null) {
        throw ValidationException('Measurement unit not found.');
      }
      if (!unit.isActive) {
        throw ValidationException('Measurement unit is inactive.');
      }
      unitName = unit.name;
    } else if (selection is NewTenantUnit) {
      final name = selection.name.trim();
      if (name.isEmpty) {
        throw ValidationException('Unit name must not be empty.');
      }
      final normalized = _normalizeUnitName(name);
      _TenantUnit? existing;
      for (final unit in _tenantUnits) {
        if (_normalizeUnitName(unit.name) == normalized) {
          existing = unit;
          break;
        }
      }
      if (existing != null) {
        throw DuplicateMeasurementUnitNameException(
          name: name,
          existingUnitId: existing.id,
        );
      }
      if (scenario == FakeCatalogScenario.setBaseUnitDuplicate) {
        throw DuplicateMeasurementUnitNameException(
          name: name,
          existingUnitId: 'unit-lo',
        );
      }
      final newId = 'unit-new-${_tenantUnits.length + 1}';
      _tenantUnits.add(_TenantUnit(id: newId, name: name));
      unitName = name;
    } else {
      throw ValidationException('Invalid base unit selection.');
    }

    product.baseUnit = unitName;
    _productUnits.add(
      _ProductUnit(
        id: '${product.id}-base',
        productId: product.id,
        name: unitName,
        conversionRateToBase: 1,
        isBaseUnit: true,
        isActive: true,
      ),
    );

    return SetProductBaseUnitResult(
          productId: product.id,
          baseUnitName: unitName,
          readinessSummary: _readinessSummaryFor(product),
        )
        as TResult;
  }

  TResult _handleListProductUnits<TResult>(ListProductUnitsQuery query) {
    final product = _findProduct(query.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }

    return _productUnitsDto(product, includeInactive: query.includeInactive) as TResult;
  }

  TResult _handleAddProductConversionUnit<TResult>(
    AddProductConversionUnitCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    if (!product.hasBaseUnit) {
      throw MissingBaseUnitException();
    }

    final unitName = command.unitName.trim();
    if (unitName.isEmpty) {
      throw ValidationException('Unit name must not be empty.');
    }
    if (command.conversionRateToBase <= 0) {
      throw ValidationException('Conversion rate must be greater than zero.');
    }

    final duplicate = _findActiveProductUnitByName(product.id, unitName);
    if (duplicate != null) {
      throw DuplicateMeasurementUnitNameException(
        name: unitName,
        existingUnitId: duplicate.id,
      );
    }

    final unit = _ProductUnit(
      id: '${product.id}-unit-new-${_nextProductUnitId++}',
      productId: product.id,
      name: unitName,
      conversionRateToBase: command.conversionRateToBase,
      isBaseUnit: false,
      isActive: true,
    );
    _productUnits.add(unit);

    return ProductUnitMutationResult(
          productId: product.id,
          unit: _toProductUnitDto(unit),
        )
        as TResult;
  }

  TResult _handleDeactivateProductConversionUnit<TResult>(
    DeactivateProductConversionUnitCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }

    final unit = _findProductUnit(command.productId, command.productUnitId);
    if (unit == null) {
      throw ApplicationException('Product unit not found');
    }
    if (unit.isBaseUnit) {
      throw ValidationException('Base unit cannot be deactivated here.');
    }

    unit.isActive = false;
    return ProductUnitMutationResult(
          productId: product.id,
          unit: _toProductUnitDto(unit),
        )
        as TResult;
  }

  TResult _handleReactivateProductConversionUnit<TResult>(
    ReactivateProductConversionUnitCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }

    final unit = _findProductUnit(command.productId, command.productUnitId);
    if (unit == null) {
      throw ApplicationException('Product unit not found');
    }
    if (unit.isBaseUnit) {
      throw ValidationException('Base unit cannot be reactivated here.');
    }
    if (unit.conversionRateToBase <= 0) {
      throw ValidationException('Conversion rate must be greater than zero.');
    }

    final duplicate = _findActiveProductUnitByName(product.id, unit.name);
    if (duplicate != null && duplicate.id != unit.id) {
      throw DuplicateMeasurementUnitNameException(
        name: unit.name,
        existingUnitId: duplicate.id,
      );
    }

    unit.isActive = true;
    return ProductUnitMutationResult(
          productId: product.id,
          unit: _toProductUnitDto(unit),
        )
        as TResult;
  }

  TResult _handleDeleteProductConversionUnit<TResult>(
    DeleteProductConversionUnitCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }

    final unit = _findProductUnit(command.productId, command.productUnitId);
    if (unit == null) {
      throw ApplicationException('Product unit not found');
    }
    if (unit.isBaseUnit) {
      throw ValidationException('Base unit cannot be deleted here.');
    }
    if (unit.hasCompletePriceBand || unit.hasTransactionUsage) {
      throw ProductConversionUnitDeleteBlockedException();
    }

    _productUnits.remove(unit);
    return null as TResult;
  }

  ProductUnitsDto _productUnitsDto(
    _StoredProduct product, {
    required bool includeInactive,
  }) {
    final units = _productUnits
        .where(
          (unit) => unit.productId == product.id && (includeInactive || unit.isActive),
        )
        .map(_toProductUnitDto)
        .toList(growable: false);

    return ProductUnitsDto(
      productId: product.id,
      baseUnitName: product.baseUnit,
      units: units,
    );
  }

  ProductUnitDto _toProductUnitDto(_ProductUnit unit) {
    return ProductUnitDto(
      id: unit.id,
      name: unit.name,
      conversionRateToBase: unit.conversionRateToBase,
      isBaseUnit: unit.isBaseUnit,
      isActive: unit.isActive,
    );
  }

  _ProductUnit? _findProductUnit(String productId, String productUnitId) {
    for (final unit in _productUnits) {
      if (unit.productId == productId && unit.id == productUnitId) {
        return unit;
      }
    }
    return null;
  }

  _ProductUnit? _findActiveProductUnitByName(String productId, String name) {
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

  TResult _handleCheckDuplicate<TResult>(CheckDuplicateProductCodeQuery query) {
    switch (scenario) {
      case FakeCatalogScenario.guidedCreateDupSku:
        final sku = query.sku?.trim();
        if (sku != null && sku.isNotEmpty) {
          return [
                ProductDuplicateMatchDto(
                  field: ProductDuplicateField.sku,
                  productId: 'product-existing-1',
                  productName: 'Existing Product',
                  matchedValue: sku,
                ),
              ]
              as TResult;
        }
        return <ProductDuplicateMatchDto>[] as TResult;
      case FakeCatalogScenario.guidedCreateDupBarcode:
        final barcode = query.barcode?.trim();
        if (barcode != null && barcode.isNotEmpty) {
          return [
                ProductDuplicateMatchDto(
                  field: ProductDuplicateField.barcode,
                  productId: 'product-existing-1',
                  productName: 'Existing Product',
                  matchedValue: barcode,
                ),
              ]
              as TResult;
        }
        return <ProductDuplicateMatchDto>[] as TResult;
      default:
        final matches = <ProductDuplicateMatchDto>[];
        final sku = query.sku?.trim();
        if (sku != null && sku.isNotEmpty) {
          final normalizedSku = _normalizeSku(sku);
          for (final product in _products) {
            if (!product.isSoftDeleted &&
                _normalizeSku(product.sku) == normalizedSku &&
                product.id != query.excludeProductId) {
              matches.add(
                ProductDuplicateMatchDto(
                  field: ProductDuplicateField.sku,
                  productId: product.id,
                  productName: product.name,
                  matchedValue: sku,
                ),
              );
            }
          }
        }
        final barcode = query.barcode?.trim();
        if (barcode != null && barcode.isNotEmpty) {
          for (final product in _products) {
            if (!product.isSoftDeleted &&
                product.barcode == barcode &&
                product.id != query.excludeProductId) {
              matches.add(
                ProductDuplicateMatchDto(
                  field: ProductDuplicateField.barcode,
                  productId: product.id,
                  productName: product.name,
                  matchedValue: barcode,
                ),
              );
            }
          }
        }
        return matches as TResult;
    }
  }

  _StorePriceRule? _storeRuleForTenant(String tenantId) {
    if (scenario == FakeCatalogScenario.scnContractE06U02Fr01_03 && tenantId == 'tenant-no-rule') {
      return null;
    }
    final rule = _storeRules[tenantId];
    if (rule == null) {
      return null;
    }
    if (scenario == FakeCatalogScenario.scnContractE06U02Fr02_03) {
      return _StorePriceRule(
        id: rule.id,
        tenantId: rule.tenantId,
        name: rule.name,
        listMarkupRatio: rule.listMarkupRatio,
        floorMarkupRatio: rule.floorMarkupRatio,
        status: StorePriceRuleStatus.inactive,
        updatedAt: rule.updatedAt,
      );
    }
    return rule;
  }

  TResult _handleGetStorePriceRule<TResult>(GetStorePriceRuleQuery query) {
    final rule = _storeRuleForTenant(query.tenantId);
    return rule?.toDto() as TResult;
  }

  TResult _handleSetStorePriceRule<TResult>(SetStorePriceRuleCommand command) {
    if (scenario == FakeCatalogScenario.scnContractE06U02Fr01_02 ||
        command.listMarkupRatio < 0 ||
        command.floorMarkupRatio < 0) {
      throw ValidationException('Tỷ lệ cộng thêm không hợp lệ.');
    }

    final existing = _storeRules[command.tenantId];
    final status = command.status;
    final isCreate = existing == null;
    final isNoOp =
        !isCreate &&
        existing!.name == command.name &&
        existing.listMarkupRatio == command.listMarkupRatio &&
        existing.floorMarkupRatio == command.floorMarkupRatio &&
        existing.status == status;

    final listBefore = existing?.listMarkupRatio;
    final floorBefore = existing?.floorMarkupRatio;

    if (existing != null) {
      existing
        ..name = command.name
        ..listMarkupRatio = command.listMarkupRatio
        ..floorMarkupRatio = command.floorMarkupRatio
        ..status = status
        ..updatedAt = DateTime.utc(2026, 7, 6);
      if (!isNoOp) {
        _appendStoreRuleHistory(
          tenantId: command.tenantId,
          summary: 'Cập nhật khung giá cửa hàng',
          listBefore: listBefore,
          listAfter: command.listMarkupRatio,
          floorBefore: floorBefore,
          floorAfter: command.floorMarkupRatio,
        );
        _recalculateRuleBasedPriceBands(existing);
      }
      return SetStorePriceRuleResult(rule: existing.toDto()) as TResult;
    }

    final rule = _StorePriceRule(
      id: 'rule-${command.tenantId}',
      tenantId: command.tenantId,
      name: command.name,
      listMarkupRatio: command.listMarkupRatio,
      floorMarkupRatio: command.floorMarkupRatio,
      status: status,
      updatedAt: DateTime.utc(2026, 7, 6),
    );
    _storeRules[command.tenantId] = rule;
    _appendStoreRuleHistory(
      tenantId: command.tenantId,
      summary: 'Tạo khung giá cửa hàng',
      listAfter: command.listMarkupRatio,
      floorAfter: command.floorMarkupRatio,
    );
    return SetStorePriceRuleResult(rule: rule.toDto()) as TResult;
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

  TResult _handleGetStorePriceRuleChangeHistory<TResult>(
    GetStorePriceRuleChangeHistoryQuery query,
  ) {
    final history = _storeRuleHistory[query.tenantId] ?? const [];
    final sorted = [...history]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final newestId = sorted.isEmpty ? null : sorted.first.id;
    final page = sorted.skip(query.offset).take(query.limit).toList();

    return StorePriceRuleChangeHistoryResultDto(
          items: page
              .map((entry) => entry.toDto(isCurrent: entry.id == newestId))
              .toList(growable: false),
          totalCount: history.length,
        )
        as TResult;
  }

  TResult _handleSuggestProductUnitPrice<TResult>(
    SuggestProductUnitPriceQuery query,
  ) {
    final product = _findProduct(query.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    if (!product.hasBaseUnit) {
      throw MissingBaseUnitException();
    }

    final targetUnit = _resolveUnitForPricing(
      productId: product.id,
      productUnitId: query.productUnitId,
    );
    final unitName = targetUnit?.name ?? product.baseUnit;
    final unitId = targetUnit?.id ?? query.productUnitId;
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
          )
          as TResult;
    }

    final rule = _storeRuleForTenant(query.tenantId);
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
          )
          as TResult;
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
        )
        as TResult;
  }

  _ProductUnit? _resolveUnitForPricing({
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

  TResult _handleApplyStorePriceRule<TResult>(ApplyStorePriceRuleCommand command) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    if (!product.hasBaseUnit) {
      throw MissingBaseUnitException();
    }
    if (!product.hasBasePrice) {
      throw MissingBasePriceException();
    }

    final rule = _storeRuleForTenant(command.tenantId);
    if (rule == null) {
      throw StorePriceRuleNotFoundException();
    }
    if (rule.status != StorePriceRuleStatus.active) {
      throw StorePriceRuleInactiveException();
    }
    if (command.storePriceRuleId != null && command.storePriceRuleId != rule.id) {
      throw StorePriceRuleNotFoundException();
    }

    if (scenario == FakeCatalogScenario.scnContractE06U02Fr03_03) {
      throw StaleBasePriceException();
    }

    if (command.basePriceVersion != null && command.basePriceVersion != product.basePriceVersion) {
      throw StaleBasePriceException();
    }

    if (_productHasPriceBand(product) && !command.confirmOverwrite) {
      throw PriceBandOverwriteRequiredException(
        existingListBeforeVat: product.listBeforeVat,
        existingFloorBeforeVat: product.floorBeforeVat,
      );
    }

    final targetUnit = _resolveUnitForPricing(
      productId: product.id,
      productUnitId: command.productUnitId,
    );
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

    return ApplyStorePriceRuleResult(
          productId: product.id,
          productUnitId: command.productUnitId ?? targetUnit?.id,
          listBeforeVat: prices.listBeforeVat,
          floorBeforeVat: prices.floorBeforeVat,
          listAfterVat: prices.listBeforeVat,
          floorAfterVat: prices.floorBeforeVat,
          storePriceRuleId: rule.id,
          sourceType: PriceBandSourceType.ruleBased,
          readinessSummary: _readinessSummaryFor(product),
        )
        as TResult;
  }

  bool _productHasStructuredUnits(String productId) {
    return _productUnits.any((unit) => unit.productId == productId);
  }

  bool _productHasPriceBand(_StoredProduct product) {
    final activeUnits = _productUnits
        .where((unit) => unit.productId == product.id && unit.isActive)
        .toList(growable: false);
    if (activeUnits.isNotEmpty) {
      return activeUnits.every((unit) => unit.hasCompletePriceBand);
    }
    return product.hasPriceBand;
  }

  List<_ProductUnit> _activeUnitsForProduct(String productId) {
    return _productUnits
        .where((unit) => unit.productId == productId && unit.isActive)
        .toList(growable: false);
  }

  _ProductUnit? _resolveBaseUnit(String productId) {
    for (final unit in _productUnits) {
      if (unit.productId == productId && unit.isBaseUnit) {
        return unit;
      }
    }
    return null;
  }

  void _syncProductPriceBandSummary(_StoredProduct product) {
    final baseUnit = _resolveBaseUnit(product.id);
    if (baseUnit != null && baseUnit.hasCompletePriceBand) {
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

    if (!_productHasPriceBand(product)) {
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

  void _recalculateFormulaPriceBandsForProduct({
    required _StoredProduct product,
    required String tenantId,
  }) {
    final rule = _storeRules[tenantId];
    for (final unit in _activeUnitsForProduct(product.id)) {
      PriceBandMarkupConfig? config;
      if (unit.priceBandSourceType == PriceBandSourceType.customConfig &&
          unit.listMarkupRatio != null) {
        config = PriceBandMarkupConfig(
          listMarkupRatio: unit.listMarkupRatio!,
          floorMarkupRatio: unit.floorMarkupRatio,
        );
      } else if (unit.priceBandSourceType == PriceBandSourceType.ruleBased &&
          rule != null &&
          rule.status == StorePriceRuleStatus.active &&
          unit.storePriceRuleId == rule.id) {
        config = PriceBandMarkupConfig(
          listMarkupRatio: rule.listMarkupRatio,
          floorMarkupRatio: rule.floorMarkupRatio,
        );
      }
      final basePrice = _comparableBasePriceForUnit(product, unit);
      if (config == null || basePrice == null) {
        continue;
      }
      final prices = PriceBandMarkupCalculator.calculate(
        basePriceForUnit: basePrice,
        config: config,
      );
      unit
        ..listBeforeVat = prices.listPrice
        ..floorBeforeVat = prices.floorPrice
        ..listAfterVat = prices.listPrice
        ..floorAfterVat = prices.floorPrice;
    }

    if (!_productHasStructuredUnits(product.id)) {
      PriceBandMarkupConfig? config;
      if (product.priceBandSourceType == PriceBandSourceType.customConfig &&
          product.listMarkupRatio != null) {
        config = PriceBandMarkupConfig(
          listMarkupRatio: product.listMarkupRatio!,
          floorMarkupRatio: product.floorMarkupRatio,
        );
      } else if (product.priceBandSourceType == PriceBandSourceType.ruleBased &&
          rule != null &&
          rule.status == StorePriceRuleStatus.active &&
          product.storePriceRuleId == rule.id) {
        config = PriceBandMarkupConfig(
          listMarkupRatio: rule.listMarkupRatio,
          floorMarkupRatio: rule.floorMarkupRatio,
        );
      }
      if (config != null && product.baseCost != null) {
        final prices = PriceBandMarkupCalculator.calculate(
          basePriceForUnit: product.baseCost!,
          config: config,
        );
        product
          ..listBeforeVat = prices.listPrice
          ..floorBeforeVat = prices.floorPrice
          ..listAfterVat = prices.listPrice
          ..floorAfterVat = prices.floorPrice;
      }
    }
    _syncProductPriceBandSummary(product);
  }

  void _recalculateRuleBasedPriceBands(_StorePriceRule rule) {
    if (rule.status != StorePriceRuleStatus.active) {
      return;
    }
    for (final product in _products) {
      _recalculateFormulaPriceBandsForProduct(
        product: product,
        tenantId: rule.tenantId,
      );
    }
  }

  double? _comparableBasePriceForUnit(_StoredProduct product, _ProductUnit unit) {
    if (!product.hasBasePrice) {
      return null;
    }
    if (unit.isBaseUnit) {
      return product.baseCost;
    }
    if (!unit.hasConversionRate || unit.conversionRateToBase <= 0) {
      return null;
    }
    return StorePriceSuggestionCalculator.scaleBasePriceForUnit(
      basePricePerBaseUnit: product.baseCost!,
      conversionRateToBase: unit.conversionRateToBase,
    );
  }

  List<PriceBandValidationWarningDto> _computePriceBandWarnings({
    required _StoredProduct product,
    required _ProductUnit unit,
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
  }) {
    final comparableBase = _comparableBasePriceForUnit(product, unit);
    if (comparableBase == null) {
      if (!unit.isBaseUnit && product.hasBasePrice) {
        return [
          PriceBandValidationWarningDto(
            code: 'cannot_compare_base_price',
            severity: PriceBandValidationWarningSeverity.warning,
            message: 'Không thể so sánh chắc chắn với Giá cơ sở do thiếu tỷ lệ quy đổi.',
            field: PriceBandValidationField.listBeforeVat,
            baseUnitName: product.baseUnit,
          ),
        ];
      }
      return const [];
    }

    final warnings = <PriceBandValidationWarningDto>[];
    if (listBeforeVat < comparableBase) {
      warnings.add(
        PriceBandValidationWarningDto(
          code: 'list_price_below_base_price',
          severity: PriceBandValidationWarningSeverity.warning,
          message: 'Giá niêm yết thấp hơn Giá cơ sở định giá.',
          field: PriceBandValidationField.listBeforeVat,
          comparedBasePrice: comparableBase,
          baseUnitName: product.baseUnit,
        ),
      );
    }
    if (floorBeforeVat != null && floorBeforeVat < comparableBase) {
      warnings.add(
        PriceBandValidationWarningDto(
          code: 'floor_price_below_base_price',
          severity: PriceBandValidationWarningSeverity.strongWarning,
          message: 'Giá sàn thấp hơn Giá cơ sở định giá.',
          field: PriceBandValidationField.floorBeforeVat,
          comparedBasePrice: comparableBase,
          baseUnitName: product.baseUnit,
        ),
      );
    }
    return warnings;
  }

  ProductUnitPriceBandRowDto _toPriceBandRowDto(
    _StoredProduct product,
    _ProductUnit unit,
  ) {
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
      isMissing: !unit.hasCompletePriceBand,
      sourceType: unit.priceBandSourceType,
      storePriceRuleName: unit.storePriceRuleName,
      listMarkupRatio: unit.listMarkupRatio,
      floorMarkupRatio: unit.floorMarkupRatio,
      isCustomOverride: unit.isCustomOverride,
    );
  }

  TResult _handleGetProductPriceBandSnapshot<TResult>(
    GetProductPriceBandSnapshotQuery query,
  ) {
    _assertCatalogReadPermission();

    if (scenario == FakeCatalogScenario.scnContractE06U04Validation) {
      if (query.items.isEmpty) {
        throw ValidationException('At least one item is required.');
      }
      if (query.items.length > 100) {
        throw ValidationException('At most 100 items can be read at once.');
      }
    }

    final capturedAt = DateTime.now().toUtc();
    final items = query.items
        .map(
          (item) => _buildPriceBandSnapshotItem(
            item: item,
            capturedAt: capturedAt,
          ),
        )
        .toList(growable: false);

    return ProductPriceBandSnapshotDto(items: items) as TResult;
  }

  ProductPriceBandSnapshotItemDto _buildPriceBandSnapshotItem({
    required ProductPriceBandSnapshotRequest item,
    required DateTime capturedAt,
  }) {
    final product = _findProduct(item.productId);
    if (product == null || product.isSoftDeleted) {
      throw ApplicationException('Product not found');
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
        throw ApplicationException('Product not found');
      }
      final listBeforeVat = product.listBeforeVat;
      final floorBeforeVat = product.floorBeforeVat;
      final floorHidden = product.pricePermissionDenied;
      return ProductPriceBandSnapshotItemDto(
        productId: product.id,
        productUnitId: syntheticBaseId,
        unitName: product.baseUnit,
        currency: 'VND',
        listBeforeVat: listBeforeVat,
        listBeforeVatMissing: listBeforeVat == null,
        floorBeforeVat: floorHidden ? null : floorBeforeVat,
        floorBeforeVatMissing: floorBeforeVat == null,
        floorBeforeVatHidden: floorHidden,
        isUnitActive: true,
        productBusinessStatus: product.businessStatus,
        capturedAt: capturedAt,
      );
    }

    throw ApplicationException('Product not found');
  }

  ProductPriceBandSnapshotItemDto _snapshotItemFromUnit({
    required _StoredProduct product,
    required _ProductUnit unit,
    required DateTime capturedAt,
  }) {
    final floorHidden = product.pricePermissionDenied;
    final listBeforeVat = unit.isActive ? unit.listBeforeVat : null;
    final floorBeforeVat = unit.isActive && !floorHidden ? unit.floorBeforeVat : null;

    return ProductPriceBandSnapshotItemDto(
      productId: product.id,
      productUnitId: unit.id,
      unitName: unit.name,
      currency: 'VND',
      listBeforeVat: listBeforeVat,
      listBeforeVatMissing: listBeforeVat == null,
      floorBeforeVat: floorBeforeVat,
      floorBeforeVatMissing: unit.floorBeforeVat == null,
      floorBeforeVatHidden: floorHidden,
      isUnitActive: unit.isActive,
      productBusinessStatus: product.businessStatus,
      capturedAt: capturedAt,
    );
  }

  TResult _handleListProductUnitPriceBands<TResult>(
    ListProductUnitPriceBandsQuery query,
  ) {
    final product = _findProduct(query.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    if (!product.hasBaseUnit) {
      throw MissingBaseUnitException();
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
                isMissing: !product.hasPriceBand,
                sourceType: product.priceBandSourceType,
                storePriceRuleName: product.storePriceRuleName,
                listMarkupRatio: product.listMarkupRatio,
                floorMarkupRatio: product.floorMarkupRatio,
                isCustomOverride: product.isCustomOverride,
              ),
            ],
          )
          as TResult;
    }

    return ProductUnitPriceBandsDto(
          productId: product.id,
          baseUnitName: product.baseUnit,
          basePrice: product.baseCost,
          rows: structuredUnits
              .map((unit) => _toPriceBandRowDto(product, unit))
              .toList(growable: false),
        )
        as TResult;
  }

  TResult _handleSetProductUnitPriceBand<TResult>(
    SetProductUnitPriceBandCommand command,
  ) {
    final product = _findProduct(command.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    if (!product.hasBaseUnit) {
      throw MissingBaseUnitException();
    }

    if (_productHasStructuredUnits(product.id)) {
      final unitId = command.productUnitId ?? _resolveBaseUnit(product.id)?.id;
      final unit = unitId == null ? null : _findProductUnit(product.id, unitId);
      if (unit == null) {
        throw ApplicationException('Product unit not found');
      }
      if (!unit.isActive) {
        throw InactiveProductUnitException();
      }

      final values = _resolvePriceBandValues(
        command: command,
        product: product,
        unit: unit,
      );

      final warnings = _computePriceBandWarnings(
        product: product,
        unit: unit,
        listBeforeVat: values.listPrice,
        listAfterVat: values.listPrice,
        floorBeforeVat: values.floorPrice,
      );
      if (warnings.isNotEmpty && !command.confirmAcknowledgeWarnings) {
        throw PriceBandWarningsRequireAcknowledgmentException(warnings: warnings);
      }

      unit
        ..listBeforeVat = values.listPrice
        ..floorBeforeVat = values.floorPrice
        ..listAfterVat = values.listPrice
        ..floorAfterVat = values.floorPrice
        ..priceBandSourceType = command.sourceType
        ..storePriceRuleId = null
        ..storePriceRuleName = null
        ..listMarkupRatio = command.listMarkupRatio
        ..floorMarkupRatio = command.floorMarkupRatio
        ..isCustomOverride = command.sourceType == PriceBandSourceType.customConfig;

      _syncProductPriceBandSummary(product);

      return SetProductUnitPriceBandResult(
            productId: product.id,
            productUnitId: unit.id,
            listBeforeVat: values.listPrice,
            floorBeforeVat: values.floorPrice,
            listAfterVat: values.listPrice,
            floorAfterVat: values.floorPrice,
            sourceType: command.sourceType,
            listMarkupRatio: command.listMarkupRatio,
            floorMarkupRatio: command.floorMarkupRatio,
            warnings: warnings,
            readinessSummary: _readinessSummaryFor(product),
          )
          as TResult;
    }

    final syntheticUnit = _ProductUnit(
      id: '${product.id}-base',
      productId: product.id,
      name: product.baseUnit,
      conversionRateToBase: 1,
      isBaseUnit: true,
      isActive: true,
    );
    final values = _resolvePriceBandValues(
      command: command,
      product: product,
      unit: syntheticUnit,
    );
    final warnings = _computePriceBandWarnings(
      product: product,
      unit: syntheticUnit,
      listBeforeVat: values.listPrice,
      listAfterVat: values.listPrice,
      floorBeforeVat: values.floorPrice,
    );
    if (warnings.isNotEmpty && !command.confirmAcknowledgeWarnings) {
      throw PriceBandWarningsRequireAcknowledgmentException(warnings: warnings);
    }

    product
      ..listBeforeVat = values.listPrice
      ..floorBeforeVat = values.floorPrice
      ..listAfterVat = values.listPrice
      ..floorAfterVat = values.floorPrice
      ..priceBandSourceType = command.sourceType
      ..storePriceRuleId = null
      ..storePriceRuleName = null
      ..listMarkupRatio = command.listMarkupRatio
      ..floorMarkupRatio = command.floorMarkupRatio
      ..isCustomOverride = command.sourceType == PriceBandSourceType.customConfig;

    return SetProductUnitPriceBandResult(
          productId: product.id,
          productUnitId: command.productUnitId,
          listBeforeVat: values.listPrice,
          floorBeforeVat: values.floorPrice,
          listAfterVat: values.listPrice,
          floorAfterVat: values.floorPrice,
          sourceType: command.sourceType,
          listMarkupRatio: command.listMarkupRatio,
          floorMarkupRatio: command.floorMarkupRatio,
          warnings: warnings,
          readinessSummary: _readinessSummaryFor(product),
        )
        as TResult;
  }

  CalculatedPriceBand _resolvePriceBandValues({
    required SetProductUnitPriceBandCommand command,
    required _StoredProduct product,
    required _ProductUnit unit,
  }) {
    switch (command.sourceType) {
      case PriceBandSourceType.ruleBased:
        throw ValidationException(
          'Vui lòng dùng lệnh áp dụng khung giá cửa hàng.',
        );
      case PriceBandSourceType.customConfig:
        if (command.storePriceRuleId != null || command.listMarkupRatio == null) {
          throw ValidationException('Cấu hình tỷ lệ riêng không hợp lệ.');
        }
        final basePrice = _comparableBasePriceForUnit(product, unit);
        if (basePrice == null) {
          throw MissingBasePriceException();
        }
        return PriceBandMarkupCalculator.calculate(
          basePriceForUnit: basePrice,
          config: PriceBandMarkupConfig(
            listMarkupRatio: command.listMarkupRatio!,
            floorMarkupRatio: command.floorMarkupRatio,
          ),
        );
      case PriceBandSourceType.manual:
        if (command.storePriceRuleId != null ||
            command.listMarkupRatio != null ||
            command.floorMarkupRatio != null) {
          throw ValidationException('Giá thủ công không được có nguồn công thức.');
        }
        final listBeforeVat = command.listBeforeVat;
        final listAfterVat = command.listAfterVat;
        if (listBeforeVat == null || listAfterVat == null) {
          throw ValidationException('Giá niêm yết là bắt buộc.');
        }
        ProductUnitPriceBand.setManual(
          id: unit.id,
          tenantId: TenantId(command.tenantId),
          productId: ProductId(command.productId),
          productUnitId: unit.id,
          listBeforeVat: listBeforeVat,
          listAfterVat: listAfterVat,
          floorBeforeVat: command.floorBeforeVat,
          floorAfterVat: command.floorAfterVat,
        );
        return CalculatedPriceBand(
          listPrice: listBeforeVat,
          floorPrice: command.floorBeforeVat,
        );
    }
  }

  TResult _handleGetProductChangeHistory<TResult>(
    GetProductChangeHistoryQuery query,
  ) {
    _assertViewHistoryPermission();

    if (scenario == FakeCatalogScenario.scnContractE07U04Validation) {
      if (query.limit < 1 || query.limit > 100) {
        throw ValidationException('Limit must be between 1 and 100.');
      }
      if (query.offset < 0) {
        throw ValidationException('Offset must be zero or greater.');
      }
    }

    final product = _findProduct(query.productId);
    if (product == null) {
      throw ApplicationException('Product not found');
    }

    final maskPricing =
        scenario == FakeCatalogScenario.scnContractE07U04Fr03_02 || product.pricePermissionDenied;

    var entries = _buildFullChangeHistoryForProduct(product);
    if (query.changeCategories.isNotEmpty) {
      final allowed = query.changeCategories.toSet();
      entries = entries
          .where(
            (entry) => entry.changeCategory != null && allowed.contains(entry.changeCategory),
          )
          .toList(growable: false);
    }

    entries = entries
        .map(
          (entry) => _maskChangeHistoryEntry(
            entry: entry,
            maskPricing: maskPricing,
          ),
        )
        .toList(growable: false);

    entries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final start = query.offset.clamp(0, entries.length);
    final end = (query.offset + query.limit).clamp(0, entries.length);
    final page = entries.sublist(start, end);

    return ProductChangeHistoryResultDto(
          productId: query.productId,
          items: page,
          totalCount: entries.length,
        )
        as TResult;
  }

  List<ProductChangeHistoryEntryDto> _buildFullChangeHistoryForProduct(
    _StoredProduct product,
  ) {
    if (scenario == FakeCatalogScenario.scnContractE07U04Fr02_02 && product.id == 'product-6') {
      return const [];
    }

    if (product.id != 'product-1' &&
        product.statusHistory.isEmpty &&
        scenario != FakeCatalogScenario.scnContractE07U04Fr02_01) {
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
