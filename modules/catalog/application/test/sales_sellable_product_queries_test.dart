import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingCatalogSalesReadGateway implements ICatalogSalesReadGateway {
  String? lastTenantId;
  String? lastStoreId;
  String? lastKeyword;
  String? lastBarcode;
  String? lastProductId;
  int? lastLimit;
  int? lastOffset;
  List<String>? lastProductIds;
  int resolveCallCount = 0;

  List<SellableProductDto> searchResults = const [];
  List<SellableProductDto> barcodeResults = const [];
  List<SellableProductUnitDto> unitResults = const [];
  List<SellableProductResolutionDto> resolutionResults = const [];

  @override
  Future<List<SellableProductDto>> searchSellableProducts({
    required String tenantId,
    required String storeId,
    required String keyword,
    required int limit,
    required int offset,
  }) async {
    lastTenantId = tenantId;
    lastStoreId = storeId;
    lastKeyword = keyword;
    lastLimit = limit;
    lastOffset = offset;
    return searchResults;
  }

  @override
  Future<List<SellableProductDto>> resolveSellableBarcode({
    required String tenantId,
    required String storeId,
    required String barcode,
  }) async {
    lastTenantId = tenantId;
    lastStoreId = storeId;
    lastBarcode = barcode;
    return barcodeResults;
  }

  @override
  Future<List<SellableProductUnitDto>> listSellableProductUnits({
    required String tenantId,
    required String storeId,
    required String productId,
  }) async {
    lastTenantId = tenantId;
    lastStoreId = storeId;
    lastProductId = productId;
    return unitResults;
  }

  @override
  Future<List<SellableProductResolutionDto>> resolveSellableProducts({
    required String tenantId,
    required String storeId,
    required List<String> productIds,
  }) async {
    resolveCallCount += 1;
    lastTenantId = tenantId;
    lastStoreId = storeId;
    lastProductIds = productIds;
    return resolutionResults;
  }
}

const _activeUnit = SellableProductUnitDto(
  productUnitId: 'unit-1',
  unitCode: 'BOX',
  unitName: 'Box',
  barcode: '8930000000001',
  isDefault: true,
  isActive: true,
  isSellable: true,
  blockReason: null,
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
);

const _sellableProduct = SellableProductDto(
  productId: 'product-1',
  sku: 'SKU-001',
  displayName: 'Thuoc A',
  isSellable: true,
  blockReason: null,
  currencyCode: 'VND',
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
  units: [_activeUnit],
);

const _secondSellableProduct = SellableProductDto(
  productId: 'product-2',
  sku: 'SKU-002',
  displayName: 'Thuoc B',
  isSellable: true,
  blockReason: null,
  currencyCode: 'VND',
  listPriceMinor: 250000,
  floorPriceMinor: 200000,
  availableStockMicros: 24000000,
  units: [_activeUnit],
);

void main() {
  group('SearchSellableProductsQueryHandler', () {
    test('forwards the tenant, store, and trimmed keyword to the gateway', () async {
      final gateway = _RecordingCatalogSalesReadGateway()..searchResults = const [_sellableProduct];
      final handler = SearchSellableProductsQueryHandler(
        readGateway: gateway,
        validator: SearchSellableProductsQueryValidator(),
      );

      final result = await handler.handle(
        SearchSellableProductsQuery(
          tenantId: 'tenant-1',
          storeId: 'store-1',
          keyword: '  thuoc a  ',
          limit: 4,
          offset: 0,
        ),
      );

      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastStoreId, 'store-1');
      expect(gateway.lastKeyword, 'thuoc a');
      expect(gateway.lastLimit, 4);
      expect(gateway.lastOffset, 0);
      expect(result.single.productId, 'product-1');
    });

    test('rejects blank scope and invalid pagination', () async {
      final handler = SearchSellableProductsQueryHandler(
        readGateway: _RecordingCatalogSalesReadGateway(),
        validator: SearchSellableProductsQueryValidator(),
      );

      await expectLater(
        handler.handle(
          SearchSellableProductsQuery(
            tenantId: ' ',
            storeId: 'store-1',
            keyword: 'thuoc',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          SearchSellableProductsQuery(
            tenantId: 'tenant-1',
            storeId: ' ',
            keyword: 'thuoc',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          SearchSellableProductsQuery(
            tenantId: 'tenant-1',
            storeId: 'store-1',
            keyword: 'thuoc',
            limit: 0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          SearchSellableProductsQuery(
            tenantId: 'tenant-1',
            storeId: 'store-1',
            keyword: 'thuoc',
            limit: 101,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          SearchSellableProductsQuery(
            tenantId: 'tenant-1',
            storeId: 'store-1',
            keyword: 'thuoc',
            offset: -1,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ResolveSellableBarcodeQueryHandler', () {
    test('forwards scope and returns every authoritative barcode match', () async {
      final gateway = _RecordingCatalogSalesReadGateway()
        ..barcodeResults = const [_sellableProduct, _secondSellableProduct];
      final handler = ResolveSellableBarcodeQueryHandler(
        readGateway: gateway,
        validator: ResolveSellableBarcodeQueryValidator(),
      );

      final result = await handler.handle(
        ResolveSellableBarcodeQuery(
          tenantId: 'tenant-1',
          storeId: 'store-1',
          barcode: '  8930000000001  ',
        ),
      );

      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastStoreId, 'store-1');
      expect(gateway.lastBarcode, '8930000000001');
      expect(result.map((item) => item.productId), ['product-1', 'product-2']);
    });

    test('rejects blank tenant, store, and barcode', () async {
      final handler = ResolveSellableBarcodeQueryHandler(
        readGateway: _RecordingCatalogSalesReadGateway(),
        validator: ResolveSellableBarcodeQueryValidator(),
      );

      await expectLater(
        handler.handle(
          ResolveSellableBarcodeQuery(
            tenantId: ' ',
            storeId: 'store-1',
            barcode: '8930000000001',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          ResolveSellableBarcodeQuery(
            tenantId: 'tenant-1',
            storeId: ' ',
            barcode: '8930000000001',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          ResolveSellableBarcodeQuery(
            tenantId: 'tenant-1',
            storeId: 'store-1',
            barcode: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ResolveSellableProductsQueryHandler', () {
    test('resolves a deduped batch in one gateway call', () async {
      final gateway = _RecordingCatalogSalesReadGateway()
        ..resolutionResults = const [
          SellableProductResolutionDto(
            productId: 'product-1',
            resolution: SellableProductResolution.sellable,
            product: _sellableProduct,
          ),
          SellableProductResolutionDto(
            productId: 'product-2',
            resolution: SellableProductResolution.notFound,
          ),
        ];
      final handler = ResolveSellableProductsQueryHandler(
        readGateway: gateway,
        validator: ResolveSellableProductsQueryValidator(),
      );

      final result = await handler.handle(
        ResolveSellableProductsQuery(
          tenantId: 'tenant-1',
          storeId: 'store-1',
          productIds: const [' product-1 ', 'product-2', 'product-1'],
        ),
      );

      expect(gateway.resolveCallCount, 1);
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastStoreId, 'store-1');
      expect(gateway.lastProductIds, ['product-1', 'product-2']);
      expect(result.map((item) => item.resolution), [
        SellableProductResolution.sellable,
        SellableProductResolution.notFound,
      ]);
    });

    test('rejects blank scope, empty ids, blank ids, and oversized batches', () async {
      final handler = ResolveSellableProductsQueryHandler(
        readGateway: _RecordingCatalogSalesReadGateway(),
        validator: ResolveSellableProductsQueryValidator(),
      );

      await expectLater(
        handler.handle(
          ResolveSellableProductsQuery(
            tenantId: ' ',
            storeId: 'store-1',
            productIds: const ['product-1'],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          ResolveSellableProductsQuery(
            tenantId: 'tenant-1',
            storeId: ' ',
            productIds: const ['product-1'],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          ResolveSellableProductsQuery(
            tenantId: 'tenant-1',
            storeId: 'store-1',
            productIds: const [],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          ResolveSellableProductsQuery(
            tenantId: 'tenant-1',
            storeId: 'store-1',
            productIds: const ['product-1', ' '],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          ResolveSellableProductsQuery(
            tenantId: 'tenant-1',
            storeId: 'store-1',
            productIds: List.generate(
              ResolveSellableProductsQuery.maxProductIds + 1,
              (index) => 'product-$index',
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ListSellableProductUnitsQueryHandler', () {
    test('forwards scope and only requests sellable product units', () async {
      final gateway = _RecordingCatalogSalesReadGateway()..unitResults = const [_activeUnit];
      final handler = ListSellableProductUnitsQueryHandler(
        readGateway: gateway,
        validator: ListSellableProductUnitsQueryValidator(),
      );

      final result = await handler.handle(
        ListSellableProductUnitsQuery(
          tenantId: 'tenant-1',
          storeId: 'store-1',
          productId: 'product-1',
        ),
      );

      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastStoreId, 'store-1');
      expect(gateway.lastProductId, 'product-1');
      expect(result, const [_activeUnit]);
      expect(result.every((unit) => unit.isActive), isTrue);
    });

    test('rejects blank tenant, store, and product', () async {
      final handler = ListSellableProductUnitsQueryHandler(
        readGateway: _RecordingCatalogSalesReadGateway(),
        validator: ListSellableProductUnitsQueryValidator(),
      );

      await expectLater(
        handler.handle(
          ListSellableProductUnitsQuery(
            tenantId: ' ',
            storeId: 'store-1',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          ListSellableProductUnitsQuery(
            tenantId: 'tenant-1',
            storeId: ' ',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        handler.handle(
          ListSellableProductUnitsQuery(
            tenantId: 'tenant-1',
            storeId: 'store-1',
            productId: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
