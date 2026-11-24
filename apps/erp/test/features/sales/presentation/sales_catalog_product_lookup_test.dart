import '../../iam/support/iam_test_session.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:erp/features/sales/presentation.dart';

import 'package:erp/features/sales/presentation/lookups/sales_catalog_product_lookup.dart';

void main() {
  late GetIt di;
  late _RecordingProductRepository catalog;

  setUp(() {
    di = GetIt.asNewInstance();
    catalog = _RecordingProductRepository();
    di
      ..registerSingleton<ProductRepository>(catalog)
      ..registerSingleton<SessionController>(
        testSessionController(tenantId: 'tenant-1', userId: 'user-1', activeStoreId: 'store-1'),
      );
  });

  test('search passes tenant, active store, limit, and maps owner fields', () async {
    catalog.products = const [_product];

    final result = await SalesCatalogProductLookup.bindSearch(di)(
      '  thuoc  ',
      limit: 4,
    );

    expect(catalog.lastStoreId, 'store-1');
    expect(catalog.lastKeyword, 'thuoc');
    expect(catalog.lastLimit, 4);
    expect(result.single.productId, '11111111-1111-1111-1111-111111111111');
    expect(result.single.tradeName, 'Biet duoc A');
    expect(result.single.units.single.productUnitId, '22222222-2222-2222-2222-222222222222');
    expect(result.single.units.single.unitPrice.amountMinor, 125000);
    expect(result.single.units.single.floorUnitPrice?.amountMinor, 100000);
    expect(result.single.stockQuantity, 12);
    expect(result.single.availabilityLabel, 'Tồn 12');
  });

  test('availabilityLabel maps positive stock to Tồn X and zero or negative stock to Hết hàng', () async {
    const pZeroStock = SellableProductDto(
      productId: '44444444-4444-4444-4444-444444444444',
      sku: 'SKU-003',
      displayName: 'Thuoc Het Hang',
      tradeName: null,
      isSellable: true,
      blockReason: null,
      currencyCode: 'VND',
      listPriceMinor: 10000,
      floorPriceMinor: null,
      availableStockMicros: 0,
      units: [],
    );
    const pNegStock = SellableProductDto(
      productId: '55555555-5555-5555-5555-555555555555',
      sku: 'SKU-004',
      displayName: 'Thuoc Am Hang',
      tradeName: null,
      isSellable: true,
      blockReason: null,
      currencyCode: 'VND',
      listPriceMinor: 10000,
      floorPriceMinor: null,
      availableStockMicros: -5000000,
      units: [],
    );
    catalog.products = const [_product, pZeroStock, pNegStock, _product2];

    final result = await SalesCatalogProductLookup.bindSearch(di)('thuoc');

    expect(result[0].availabilityLabel, 'Tồn 12');
    expect(result[1].availabilityLabel, 'Hết hàng');
    expect(result[2].availabilityLabel, 'Hết hàng');
    expect(result[3].availabilityLabel, isNull);
  });

  test('barcode preserves multiple matches and units use focused query', () async {
    catalog.products = const [_product, _product2];
    final matches = await SalesCatalogProductLookup.bindBarcode(di)('8930001');
    expect(matches, hasLength(2));
    expect(catalog.lastBarcode, '8930001');

    catalog.units = const [_unit];
    final resolved = await SalesCatalogProductLookup.bindUnits(di)(matches.first);
    expect(catalog.lastStoreId, 'store-1');
    expect(catalog.lastProductId, matches.first.productId);
    expect(resolved.units.single.productUnitId, _unit.productUnitId);
  });

  test('catalog failure surfaces fallback message on generic error', () async {
    catalog.failure = StateError('offline');

    await expectLater(
      SalesCatalogProductLookup.bindSearch(di)('thuoc'),
      throwsA(
        isA<SalesExternalOperationException>().having(
          (error) => error.message,
          'message',
          'Không thể tải sản phẩm. Vui lòng thử lại.',
        ),
      ),
    );
  });

  test('catalog failure surfaces permission message on noPermission (H18)', () async {
    catalog.failure = const AppException(AppErrorCode.noPermission);

    await expectLater(
      SalesCatalogProductLookup.bindSearch(di)('thuoc'),
      throwsA(
        isA<SalesExternalOperationException>().having(
          (error) => error.message,
          'message',
          'Bạn không có quyền thực hiện thao tác này.',
        ),
      ),
    );
  });
}

final class _RecordingProductRepository extends Fake implements ProductRepository {
  String? lastStoreId;
  String? lastKeyword;
  int? lastLimit;
  String? lastBarcode;
  String? lastProductId;

  List<SellableProductDto> products = const [];
  List<SellableProductUnitDto> units = const [];
  Object? failure;

  @override
  Future<List<SellableProductDto>> searchSellable({
    required String storeId,
    String? keyword,
    int limit = 50,
    int offset = 0,
  }) async {
    lastStoreId = storeId;
    lastKeyword = keyword;
    lastLimit = limit;
    final error = failure;
    if (error != null) throw error;
    return products;
  }

  @override
  Future<List<SellableProductDto>> resolveSellableBarcode({
    required String storeId,
    required String barcode,
  }) async {
    lastStoreId = storeId;
    lastBarcode = barcode;
    final error = failure;
    if (error != null) throw error;
    return products;
  }

  @override
  Future<List<SellableProductUnitDto>> listSellableUnits({
    required String storeId,
    required String productId,
  }) async {
    lastStoreId = storeId;
    lastProductId = productId;
    final error = failure;
    if (error != null) throw error;
    return units;
  }
}

const _unit = SellableProductUnitDto(
  productUnitId: '22222222-2222-2222-2222-222222222222',
  unitCode: 'HOP',
  unitName: 'Hop',
  barcode: '8930001',
  isDefault: true,
  isActive: true,
  isSellable: true,
  blockReason: null,
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
);

const _product = SellableProductDto(
  productId: '11111111-1111-1111-1111-111111111111',
  sku: 'SKU-001',
  displayName: 'Thuoc A',
  tradeName: 'Biet duoc A',
  isSellable: true,
  blockReason: null,
  currencyCode: 'VND',
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
  units: [_unit],
);

const _product2 = SellableProductDto(
  productId: '33333333-3333-3333-3333-333333333333',
  sku: 'SKU-002',
  displayName: 'Thuoc B',
  tradeName: null,
  isSellable: true,
  blockReason: null,
  currencyCode: 'VND',
  listPriceMinor: 250000,
  floorPriceMinor: null,
  availableStockMicros: null,
  units: [],
);
