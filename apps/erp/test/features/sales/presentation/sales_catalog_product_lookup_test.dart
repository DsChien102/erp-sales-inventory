import '../../iam/support/iam_test_session.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/presentation/lookups/sales_catalog_product_lookup.dart';

void main() {
  late GetIt di;
  late _RecordingCatalogModule catalog;

  setUp(() {
    di = GetIt.asNewInstance();
    catalog = _RecordingCatalogModule();
    di
      ..registerSingleton<ICatalogModule>(catalog)
      ..registerSingleton<IExecutionContext>(const _ExecutionContext())
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

    final query = catalog.lastQuery as SearchSellableProductsQuery;
    expect(query.tenantId, 'tenant-1');
    expect(query.storeId, 'store-1');
    expect(query.keyword, 'thuoc');
    expect(query.limit, 4);
    expect(result.single.productId, '11111111-1111-1111-1111-111111111111');
    expect(result.single.tradeName, 'Biet duoc A');
    expect(result.single.units.single.productUnitId, '22222222-2222-2222-2222-222222222222');
    expect(result.single.units.single.unitPrice.amountMinor, 125000);
    expect(result.single.units.single.floorUnitPrice?.amountMinor, 100000);
  });

  test('barcode preserves multiple matches and units use focused query', () async {
    catalog.products = const [_product, _product2];
    final matches = await SalesCatalogProductLookup.bindBarcode(di)('8930001');
    expect(matches, hasLength(2));
    expect(catalog.lastQuery, isA<ResolveSellableBarcodeQuery>());

    catalog.units = const [_unit];
    final resolved = await SalesCatalogProductLookup.bindUnits(di)(matches.first);
    final query = catalog.lastQuery as ListSellableProductUnitsQuery;
    expect(query.storeId, 'store-1');
    expect(query.productId, matches.first.productId);
    expect(resolved.units.single.productUnitId, _unit.productUnitId);
  });

  test('catalog failure surfaces the underlying exception message', () async {
    catalog.failure = StateError('offline');

    await expectLater(
      SalesCatalogProductLookup.bindSearch(di)('thuoc'),
      throwsA(
        isA<SalesExternalOperationException>().having(
          (error) => error.message,
          'message',
          contains('offline'),
        ),
      ),
    );
  });
}

final class _RecordingCatalogModule implements ICatalogModule {
  IQuery<dynamic>? lastQuery;
  List<SellableProductDto> products = const [];
  List<SellableProductUnitDto> units = const [];
  Object? failure;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    lastQuery = query;
    final error = failure;
    if (error != null) throw error;
    if (query is ListSellableProductUnitsQuery) return units as TResult;
    return products as TResult;
  }
}

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
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
