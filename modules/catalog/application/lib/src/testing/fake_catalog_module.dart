import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'fake_catalog_product_builder.dart';
import 'fake_product_readiness_builder.dart';

/// Scenario ids aligned with `docs/themes/TH-02-product-pricing/harness/07-api-contracts.md`.
abstract final class FakeCatalogScenario {
  static const guidedCreateOk = 'guided_create_ok';
  static const guidedCreateDupSku = 'guided_create_dup_sku';
  static const guidedCreateDupBarcode = 'guided_create_dup_barcode';
  static const guidedCreateMissingName = 'guided_create_missing_name';
  static const guidedCreateNoImages = 'guided_create_no_images';
  static const guidedCreateUploadSlotOk = 'guided_create_upload_slot_ok';
  static const guidedCreateUploadInvalidType = 'guided_create_upload_invalid_type';
  static const guidedCreatePermissionDenied = 'guided_create_permission_denied';
  static const initialStockOk = 'initial_stock_ok';
  static const initialStockSkip = 'initial_stock_skip';
  static const manualBasePriceOk = 'manual_base_price_ok';
  static const priceBandFromStoreRule = 'price_band_from_store_rule';

  static const readinessManyBlockers = 'readiness_many_blockers';
  static const readinessReadyToSell = 'readiness_ready_to_sell';
  static const readinessAdvancedStockPending = 'readiness_advanced_stock_pending';
  static const readinessCostingBasePricePending = 'readiness_costing_base_price_pending';
  static const readinessMissingCustomFields = 'readiness_missing_custom_fields';
  static const readinessNoPricePermission = 'readiness_no_price_permission';
  static const readinessRefreshAfterUnit = 'readiness_refresh_after_unit';
  static const readinessPermissionDenied = 'readiness_permission_denied';

  static const searchEmpty = 'search_empty';
  static const searchWithReadiness = 'search_with_readiness';
  static const barcodeExactMatch = 'barcode_exact_match';
  static const barcodeNotFound = 'barcode_not_found';

  static const pccIncomplete = 'pcc_incomplete';
  static const pccReadyToSell = 'pcc_ready_to_sell';
  static const pccInactive = 'pcc_inactive';
  static const pccCustomFieldCards = 'pcc_custom_field_cards';

  static const listTenantUnits = 'list_tenant_units';
  static const setBaseUnitExisting = 'set_base_unit_existing';
  static const setBaseUnitCreateNew = 'set_base_unit_create_new';
  static const setBaseUnitDuplicate = 'set_base_unit_duplicate';
  static const setBaseUnitInactiveUnit = 'set_base_unit_inactive_unit';
  static const unitDependenciesLocked = 'unit_dependencies_locked';
  static const scnContractE05U01Fr01_01 = 'scn_contract_e05_u01_fr01_01';
  static const scnContractE05U01Fr02_01 = 'scn_contract_e05_u01_fr02_01';
  static const scnContractE05U01Fr03_01 = 'scn_contract_e05_u01_fr03_01';
  static const scnContractE05U02Fr01_01 = 'scn_contract_e05_u02_fr01_01';
  static const scnContractE05U02Fr01_02 = 'scn_contract_e05_u02_fr01_02';
  static const scnContractE05U02Fr02_01 = 'scn_contract_e05_u02_fr02_01';
  static const scnContractE05U02Fr02_02 = 'scn_contract_e05_u02_fr02_02';
  static const scnContractE05U02Fr02_03 = 'scn_contract_e05_u02_fr02_03';
  static const scnContractE05U02Fr03_01 = 'scn_contract_e05_u02_fr03_01';
  static const scnContractE05U02Fr04_01 = 'scn_contract_e05_u02_fr04_01';
}

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
  });

  final String id;
  final String productId;
  final String name;
  final double conversionRateToBase;
  final bool isBaseUnit;
  bool isActive;
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
  final double quantityBefore;
  final double quantityAfter;
  final double delta;
  final String? reason;
}

class _StoredProduct {
  _StoredProduct({
    required this.id,
    required this.name,
    this.tradeName,
    required this.sku,
    required this.barcode,
    required this.baseUnit,
    this.images = const [],
    this.stockQty,
    this.baseCost,
    this.listPrice,
    this.floorPrice,
    this.notes,
    this.hasRequiredCustomFields = true,
    this.stockMode = FakeProductReadinessBuilder.stockModeBasic,
    this.basePriceMode = FakeProductReadinessBuilder.basePriceModeManual,
    this.pricePermissionDenied = false,
    this.businessStatus = ProductStatus.active,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.utc(2026, 1, 1);

  final String id;
  final String name;
  final String? tradeName;
  final String sku;
  final String barcode;
  String baseUnit;
  final List<String> images;
  int? stockQty;
  int stockVersion = 1;
  List<_StockMovement> stockMovements = const [];
  double? baseCost;
  double? listPrice;
  double? floorPrice;
  bool useStoreRule = false;
  final String? notes;
  final String? description = null;
  final bool hasRequiredCustomFields;
  final StockMode stockMode;
  final BasePriceMode basePriceMode;
  final bool pricePermissionDenied;
  final ProductStatus businessStatus;
  final bool isSoftDeleted = false;
  final DateTime updatedAt;

  bool get hasBaseUnit => baseUnit.trim().isNotEmpty;

  bool get hasImages => images.isNotEmpty;

  bool get hasStock => stockQty != null;

  bool get hasBasePrice => baseCost != null;

  bool get hasPriceBand => listPrice != null && floorPrice != null;
}

final class FakeCatalogModule implements ICatalogModule {
  FakeCatalogModule({this.scenario = FakeCatalogScenario.guidedCreateOk})
    : _tenantUnits = [
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
        ),
        _ProductUnit(
          id: 'product-1-unit-vi',
          productId: 'product-1',
          name: 'Vỉ',
          conversionRateToBase: 10,
          isBaseUnit: false,
          isActive: true,
        ),
        _ProductUnit(
          id: 'product-1-unit-thung',
          productId: 'product-1',
          name: 'Thùng',
          conversionRateToBase: 100,
          isBaseUnit: false,
          isActive: false,
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
          listPrice: 120000,
          floorPrice: 95000,
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
          listPrice: 25000,
          floorPrice: 18000,
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
          listPrice: 70000,
          floorPrice: 55000,
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
          listPrice: 45000,
          floorPrice: 35000,
          businessStatus: ProductStatus.inactive,
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
      ];

  final String scenario;
  final List<_TenantUnit> _tenantUnits;
  final List<_ProductUnit> _productUnits;
  final List<_StoredProduct> _products;
  int _nextProductId = 6;
  int _nextProductUnitId = 1;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is CreateProductCommand) {
      return _handleCreateProduct<TResult>(command as CreateProductCommand);
    } else if (command is SetInitialStockCommand) {
      final cmd = command as SetInitialStockCommand;
      if (cmd.mode != 'basic') {
        throw NotBasicStockModeException();
      }
      final prod = _products.firstWhere((p) => p.id == cmd.productId);
      if (!prod.hasBaseUnit) {
        throw MissingBaseUnitException();
      }
      final previousQty = (prod.stockQty ?? 0).toDouble();
      prod.stockQty = cmd.quantity.toInt();
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
      return SetInitialStockResult(
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
      final previousQty = (prod.stockQty ?? 0).toDouble();
      if (cmd.expectedQuantity != null && cmd.expectedQuantity != previousQty) {
        throw StaleStockQuantityException();
      }
      prod.stockQty = cmd.newQuantity.toInt();
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
      final prod = _products.firstWhere((p) => p.id == cmd.productId);
      if (!prod.hasBaseUnit) {
        throw MissingBaseUnitException();
      }
      prod.baseCost = cmd.basePrice;
      return null as TResult;
    } else if (command is SetInitialPriceBandCommand) {
      final cmd = command as SetInitialPriceBandCommand;
      final useRule = cmd.useStoreRule ?? false;
      if (useRule && (cmd.listPrice == null || cmd.floorPrice == null)) {
        throw MissingBasePriceException();
      }
      if (cmd.listPrice != null && cmd.floorPrice != null && cmd.floorPrice! > cmd.listPrice!) {
        throw FloorPriceGreaterThanListPriceException();
      }
      final prod = _products.firstWhere((p) => p.id == cmd.productId);
      if (!prod.hasBaseUnit) {
        throw MissingBaseUnitException();
      }
      prod.listPrice = cmd.listPrice;
      prod.floorPrice = cmd.floorPrice;
      prod.useStoreRule = useRule;
      return null as TResult;
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
    throw UnimplementedError('Unexpected query: ${query.runtimeType}');
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
    final images = hasImages ? command.images.map((img) => img.storageKey).toList() : <String>[];

    final product = _StoredProduct(
      id: productId,
      name: command.productName,
      tradeName: command.commercialName,
      sku: command.sku ?? '',
      barcode: command.barcode ?? '',
      baseUnit: command.baseUnitName ?? '',
      images: images,
      stockQty: hasStock ? 0 : null,
      baseCost: hasBasePrice ? 0 : null,
      listPrice: hasPriceBand ? 1 : null,
      floorPrice: hasPriceBand ? 1 : null,
      notes: command.note,
      hasRequiredCustomFields: hasRequiredCustomFields,
      stockMode: stockMode,
      basePriceMode: basePriceMode,
      pricePermissionDenied: pricePermissionDenied,
    );

    _products.add(product);

    final view = _buildReadinessView(product);
    return CreateProductResult(
      productId: productId,
      readinessSummary: view.readinessSummary,
    );
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
    if (scenario == FakeCatalogScenario.pccInactive) {
      return _findProduct('product-5') ?? _findProduct(productId);
    }
    return _findProduct(productId);
  }

  ProductControlCenterDto _toControlCenterDto(_StoredProduct product) {
    final customFieldCards = scenario == FakeCatalogScenario.pccCustomFieldCards
        ? [
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
          ]
        : const <CustomFieldGroupCardDto>[];

    final history = [
      ProductChangeHistoryEntryDto(
        id: 'history-${product.id}-1',
        occurredAt: product.updatedAt,
        actorDisplayName: 'Nguyễn Văn A',
        changeType: 'product_created',
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
      isSoftDeleted: product.isSoftDeleted,
      baseUnit: product.baseUnit,
      stockQty: product.stockQty,
      stockVersion: product.stockVersion,
      baseCost: product.baseCost,
      listPrice: product.listPrice,
      floorPrice: product.floorPrice,
      hasRequiredCustomFields: product.hasRequiredCustomFields,
      stockMode: product.stockMode,
      basePriceMode: product.basePriceMode,
      pricePermissionDenied: product.pricePermissionDenied,
      customFieldGroupCards: customFieldCards,
      changeHistoryPreview: history,
    );
  }

  List<_StoredProduct> _visibleProducts(ProductSearchCriteria criteria) {
    return _products.where((product) {
      if (product.isSoftDeleted && !criteria.includeSoftDeleted) {
        return false;
      }
      if (!criteria.businessStatuses.contains(product.businessStatus)) {
        return false;
      }
      if (!_matchesKeyword(product, criteria.keyword)) {
        return false;
      }
      if (!_matchesReadinessFilter(product, criteria.readinessFilter)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  bool _matchesKeyword(_StoredProduct product, String? keyword) {
    if (keyword == null) {
      return true;
    }
    final lower = keyword.toLowerCase();
    final fields = [
      product.name,
      product.tradeName ?? '',
      product.sku,
      product.barcode,
    ];
    for (final field in fields) {
      if (field.toLowerCase().contains(lower)) {
        return true;
      }
      if (field == keyword) {
        return true;
      }
    }
    return false;
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
      isSoftDeleted: product.isSoftDeleted,
      readinessSummary: summary,
      listPrice: product.listPrice,
      floorPrice: product.floorPrice,
      baseUnit: product.baseUnit,
      stockQuantity: product.stockQty,
      updatedAt: product.updatedAt,
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
      hasPriceBand: product.hasPriceBand,
      hasRequiredCustomFields: product.hasRequiredCustomFields,
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

  ProductReadinessViewDto _buildReadinessView(_StoredProduct product) {
    return FakeProductReadinessBuilder.build(
      productId: product.id,
      productName: product.name,
      hasBaseUnit: product.hasBaseUnit,
      hasImages: product.hasImages,
      hasStock: product.hasStock,
      hasBasePrice: product.hasBasePrice,
      hasPriceBand: product.hasPriceBand,
      hasRequiredCustomFields: product.hasRequiredCustomFields,
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
          for (final product in _products) {
            if (product.sku == sku && product.id != query.excludeProductId) {
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
            if (product.barcode == barcode && product.id != query.excludeProductId) {
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
}
