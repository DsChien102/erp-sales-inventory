import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

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
  });

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
          ),
        ];

  final String scenario;
  final List<_StoredProduct> _products;
  int _nextProductId = 4;

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
    throw UnimplementedError('Unexpected query: ${query.runtimeType}');
  }

  TResult _handleRequestUpload<TResult>(
    RequestProductImageUploadCommand command,
  ) {
    switch (scenario) {
      case FakeCatalogScenario.guidedCreatePermissionDenied:
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
        return _persistCreate(command, includeImageBlocker: true) as TResult;
      case FakeCatalogScenario.guidedCreateOk:
      default:
        return _persistCreate(command) as TResult;
    }
  }

  CreateProductResult _persistCreate(
    CreateProductCommand command, {
    bool includeImageBlocker = false,
  }) {
    final productId = 'product-new-${_nextProductId++}';

    _products.add(
      _StoredProduct(
        id: productId,
        name: command.productName,
        tradeName: command.commercialName,
        sku: command.sku ?? '',
        barcode: command.barcode ?? '',
        baseUnit: command.baseUnitName ?? '',
        images: command.images.map((img) => img.storageKey).toList(),
        notes: command.note,
      ),
    );

    return CreateProductResult(
      productId: productId,
      readinessSummary: ReadinessSummaryDto(
        status: ReadinessStatus.incomplete,
        blockers: [
          if (command.baseUnitName == null || command.baseUnitName!.trim().isEmpty)
            const ReadinessBlockerDto(
              code: ReadinessBlockerCode.missingBaseUnit,
              message: 'Thiếu đơn vị cơ sở',
              group: 'units',
            ),
          if (includeImageBlocker)
            const ReadinessBlockerDto(
              code: ReadinessBlockerCode.missingImage,
              message: 'Chưa có ảnh sản phẩm',
              group: 'profile',
            ),
          const ReadinessBlockerDto(
            code: ReadinessBlockerCode.missingPrice,
            message: 'Thiếu giá',
            group: 'pricing',
          ),
        ],
      ),
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
