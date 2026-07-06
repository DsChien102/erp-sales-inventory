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
  static const readinessCostingBasePricePending =
      'readiness_costing_base_price_pending';
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
    this.description,
    this.hasRequiredCustomFields = true,
    this.stockMode = FakeProductReadinessBuilder.stockModeBasic,
    this.basePriceMode = FakeProductReadinessBuilder.basePriceModeManual,
    this.pricePermissionDenied = false,
    this.businessStatus = ProductStatus.active,
    this.isSoftDeleted = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.utc(2026, 1, 1);

  final String id;
  final String name;
  final String? tradeName;
  final String sku;
  final String barcode;
  final String baseUnit;
  final List<String> images;
  int? stockQty;
  double? baseCost;
  double? listPrice;
  double? floorPrice;
  bool useStoreRule = false;
  final String? notes;
  final String? description;
  final bool hasRequiredCustomFields;
  final StockMode stockMode;
  final BasePriceMode basePriceMode;
  final bool pricePermissionDenied;
  final ProductStatus businessStatus;
  final bool isSoftDeleted;
  final DateTime updatedAt;

  bool get hasBaseUnit => baseUnit.trim().isNotEmpty;

  bool get hasImages => images.isNotEmpty;

  bool get hasStock => stockQty != null;

  bool get hasBasePrice => baseCost != null;

  bool get hasPriceBand => listPrice != null && floorPrice != null;
}

final class FakeCatalogModule implements ICatalogModule {
  FakeCatalogModule({this.scenario = FakeCatalogScenario.guidedCreateOk})
      : _products = [
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
        ];

  final String scenario;
  final List<_StoredProduct> _products;
  int _nextProductId = 6;

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
      prod.stockQty = cmd.quantity;
      return null as TResult;
    } else if (command is SetManualBasePriceCommand) {
      final cmd = command as SetManualBasePriceCommand;
      if (cmd.mode != 'manual') {
        throw NotManualBasePriceModeException();
      }
      final prod = _products.firstWhere((p) => p.id == cmd.productId);
      prod.baseCost = cmd.basePrice;
      return null as TResult;
    } else if (command is SetInitialPriceBandCommand) {
      final cmd = command as SetInitialPriceBandCommand;
      final useRule = cmd.useStoreRule ?? false;
      if (useRule && (cmd.listPrice == null || cmd.floorPrice == null)) {
        throw MissingBasePriceException();
      }
      if (cmd.listPrice != null &&
          cmd.floorPrice != null &&
          cmd.floorPrice! > cmd.listPrice!) {
        throw FloorPriceGreaterThanListPriceException();
      }
      final prod = _products.firstWhere((p) => p.id == cmd.productId);
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
          storageKey:
              '${command.tenantId}/staging/$slotId/original.jpeg',
          signedUploadUrl: 'https://storage.fake/upload/$slotId',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ) as TResult;
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
        ) as TResult;
      case FakeCatalogScenario.readinessManyBlockers:
        return _persistCreate(
          command,
          hasImages: false,
        ) as TResult;
      case FakeCatalogScenario.readinessAdvancedStockPending:
        return _persistCreate(
          command,
          stockMode: FakeProductReadinessBuilder.stockModeAdvanced,
        ) as TResult;
      case FakeCatalogScenario.readinessCostingBasePricePending:
        return _persistCreate(
          command,
          basePriceMode: FakeProductReadinessBuilder.basePriceModeCosting,
        ) as TResult;
      case FakeCatalogScenario.readinessMissingCustomFields:
        return _persistCreate(
          command,
          hasRequiredCustomFields: false,
        ) as TResult;
      case FakeCatalogScenario.readinessNoPricePermission:
        return _persistCreate(
          command,
          hasStock: true,
          hasBasePrice: true,
          pricePermissionDenied: true,
        ) as TResult;
      case FakeCatalogScenario.readinessRefreshAfterUnit:
        return _persistCreate(
          command,
          hasBasePrice: true,
        ) as TResult;
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
    final images = hasImages
        ? command.images.map((img) => img.storageKey).toList()
        : <String>[];

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
    final items = filtered
        .map(_toListItemDto)
        .toList(growable: false);

    final start = query.offset.clamp(0, items.length);
    final end = (query.offset + query.limit).clamp(0, items.length);
    final page = items.sublist(start, end);

    return ProductSearchResultDto(
      items: page,
      totalCount: items.length,
    ) as TResult;
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
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
      ProductReadinessFilter.readyToSell =>
        summary.status == ReadinessStatus.readyToSell,
      ProductReadinessFilter.incomplete =>
        summary.status == ReadinessStatus.incomplete,
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
          ] as TResult;
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
          ] as TResult;
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
