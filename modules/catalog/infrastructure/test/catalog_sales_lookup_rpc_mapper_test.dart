import 'dart:async';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/catalog_sales_lookup_rpc_mapper.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/supabase_catalog_sales_read_gateway.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

const _tenantId = '11111111-1111-4111-8111-111111111111';
const _storeId = '22222222-2222-4222-8222-222222222222';
const _productId = '33333333-3333-4333-8333-333333333333';
const _secondProductId = '44444444-4444-4444-8444-444444444444';
const _thirdProductId = '77777777-7777-4777-8777-777777777777';
const _unitId = '55555555-5555-4555-8555-555555555555';
const _secondUnitId = '66666666-6666-4666-8666-666666666666';

void main() {
  group('CatalogSalesLookupRpcMapper', () {
    test('maps nullable trade name, floor, and stock owner fields', () {
      final products = CatalogSalesLookupRpcMapper.productsFromPayload({
        'items': [
          _productJson(
            tradeName: null,
            floorPriceMinor: null,
            availableStockMicros: null,
          ),
        ],
      });

      expect(products.single.tradeName, isNull);
      expect(products.single.floorPriceMinor, isNull);
      expect(products.single.availableStockMicros, isNull);
      expect(products.single.units.single.floorPriceMinor, isNull);
      expect(products.single.units.single.availableStockMicros, isNull);
    });

    test('maps a blocked product without fabricating sellability', () {
      final products = CatalogSalesLookupRpcMapper.productsFromPayload({
        'items': [
          _productJson(
            isSellable: false,
            blockReason: 'product_not_ready_to_sell',
          ),
        ],
      });

      expect(products.single.isSellable, isFalse);
      expect(products.single.blockReason, 'product_not_ready_to_sell');
      expect(products.single.units.single.isSellable, isFalse);
    });

    test('preserves every authoritative barcode match and unit', () {
      final barcodeProducts = CatalogSalesLookupRpcMapper.productsFromPayload({
        'items': [
          _productJson(),
          _productJson(
            productId: _secondProductId,
            units: [_unitJson(), _unitJson(unitId: _secondUnitId, unitCode: 'PACK')],
          ),
        ],
      });

      expect(barcodeProducts.map((product) => product.productId), [
        _productId,
        _secondProductId,
      ]);
      expect(barcodeProducts.last.units.map((unit) => unit.productUnitId), [
        _unitId,
        _secondUnitId,
      ]);
    });

    test('rejects malformed identity, currency, and integer price fields', () {
      for (final payload in <Object?>[
        {
          'items': [_productJson(productId: 'not-a-uuid')],
        },
        {
          'items': [_productJson(currencyCode: 'vnd')],
        },
        {
          'items': [_productJson(listPriceMinor: 125000.5)],
        },
      ]) {
        expect(
          () => CatalogSalesLookupRpcMapper.productsFromPayload(payload),
          throwsA(isA<ApplicationException>()),
        );
      }
    });

    test('maps every resolution branch without collapsing them', () {
      final resolutions = CatalogSalesLookupRpcMapper.resolutionsFromPayload({
        'items': [
          {
            'product_id': _productId,
            'resolution': 'sellable',
            'product': _productJson(),
          },
          {
            'product_id': _secondProductId,
            'resolution': 'not_sellable',
            'product': null,
            'sku': 'SKU-002',
            'display_name': 'Thuoc B',
            'block_reason': 'product_not_ready_to_sell',
          },
          {
            'product_id': _thirdProductId,
            'resolution': 'not_found',
            'product': null,
            'sku': null,
            'display_name': null,
            'block_reason': null,
          },
        ],
      });

      expect(resolutions.map((item) => item.resolution), [
        SellableProductResolution.sellable,
        SellableProductResolution.notSellable,
        SellableProductResolution.notFound,
      ]);
      expect(resolutions[0].product?.productId, _productId);
      expect(resolutions[0].notSellable, isNull);
      expect(resolutions[1].product, isNull);
      expect(resolutions[1].notSellable?.productId, _secondProductId);
      expect(resolutions[1].notSellable?.sku, 'SKU-002');
      expect(resolutions[1].notSellable?.displayName, 'Thuoc B');
      expect(resolutions[1].notSellable?.blockReason, 'product_not_ready_to_sell');
      expect(resolutions[2].notSellable, isNull);
    });

    test('rejects unknown resolutions and sellable rows without a product', () {
      for (final payload in <Object?>[
        {
          'items': [
            {
              'product_id': _productId,
              'resolution': 'maybe',
              'product': null,
            },
          ],
        },
        {
          'items': [
            {
              'product_id': _productId,
              'resolution': 'sellable',
              'product': null,
            },
          ],
        },
        {
          'items': [
            {
              'product_id': _productId,
              'resolution': 'not_found',
              'product': _productJson(),
            },
          ],
        },
      ]) {
        expect(
          () => CatalogSalesLookupRpcMapper.resolutionsFromPayload(payload),
          throwsA(isA<ApplicationException>()),
        );
      }
    });
  });

  group('SupabaseCatalogSalesReadGateway', () {
    test('uses the exact search RPC parameter map', () async {
      final supabase = _FakeCatalogSupabaseClient({
        'search_sellable_products': (_) async => {'items': [_productJson()]},
      });
      final gateway = _gateway(supabase);

      final result = await gateway.searchSellableProducts(
        tenantId: _tenantId,
        storeId: _storeId,
        keyword: 'thuoc',
        limit: 4,
        offset: 0,
      );

      expect(result.single.productId, _productId);
      expect(result.single.tradeName, 'Biet duoc A');
      final call = supabase.calls.single;
      expect(call.functionName, 'search_sellable_products');
      expect(call.params, {
        'p_tenant_id': _tenantId,
        'p_store_id': _storeId,
        'p_keyword': 'thuoc',
        'p_limit': 4,
        'p_offset': 0,
      });
    });

    test('uses the exact barcode and unit-list RPC parameter maps', () async {
      final supabase = _FakeCatalogSupabaseClient({
        'resolve_sellable_barcode': (_) async => {
          'items': [_productJson(), _productJson(productId: _secondProductId)],
        },
        'list_sellable_product_units': (_) async => {
          'units': [_unitJson(), _unitJson(unitId: _secondUnitId, unitCode: 'PACK')],
        },
      });
      final gateway = _gateway(supabase);

      final barcodeMatches = await gateway.resolveSellableBarcode(
        tenantId: _tenantId,
        storeId: _storeId,
        barcode: '8930000000001',
      );
      final units = await gateway.listSellableProductUnits(
        tenantId: _tenantId,
        storeId: _storeId,
        productId: _productId,
      );

      expect(barcodeMatches, hasLength(2));
      expect(units, hasLength(2));
      expect(supabase.calls[0].functionName, 'resolve_sellable_barcode');
      expect(supabase.calls[0].params, {
        'p_tenant_id': _tenantId,
        'p_store_id': _storeId,
        'p_barcode': '8930000000001',
      });
      expect(supabase.calls[1].functionName, 'list_sellable_product_units');
      expect(supabase.calls[1].params, {
        'p_tenant_id': _tenantId,
        'p_store_id': _storeId,
        'p_product_id': _productId,
      });
    });

    test('resolves a batch of ids in a single RPC call', () async {
      final supabase = _FakeCatalogSupabaseClient({
        'resolve_sellable_products': (_) async => {
          'items': [
            {
              'product_id': _productId,
              'resolution': 'sellable',
              'product': _productJson(),
            },
            {
              'product_id': _secondProductId,
              'resolution': 'not_found',
              'product': null,
            },
          ],
        },
      });
      final gateway = _gateway(supabase);

      final resolutions = await gateway.resolveSellableProducts(
        tenantId: _tenantId,
        storeId: _storeId,
        productIds: const [_productId, _secondProductId],
      );

      expect(resolutions, hasLength(2));
      expect(supabase.calls.single.functionName, 'resolve_sellable_products');
      expect(supabase.calls.single.params, {
        'p_tenant_id': _tenantId,
        'p_store_id': _storeId,
        'p_product_ids': [_productId, _secondProductId],
      });
    });

    test('maps malformed RPC payloads to Catalog application exceptions', () async {
      final supabase = _FakeCatalogSupabaseClient({
        'search_sellable_products': (_) async => {'items': 'not-a-list'},
      });
      final gateway = _gateway(supabase);

      await expectLater(
        gateway.searchSellableProducts(
          tenantId: _tenantId,
          storeId: _storeId,
          keyword: 'thuoc',
          limit: 4,
          offset: 0,
        ),
        throwsA(isA<ApplicationException>()),
      );
    });
  });
}

SupabaseCatalogSalesReadGateway _gateway(_FakeCatalogSupabaseClient supabase) {
  return SupabaseCatalogSalesReadGateway(
    rpcClient: SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'catalog',
      mapError: (error, [stackTrace]) => RpcException(error.toString()),
    ),
  );
}

Map<String, dynamic> _productJson({
  String productId = _productId,
  String? sku = 'SKU-001',
  String displayName = 'Thuoc A',
  String? tradeName = 'Biet duoc A',
  bool isSellable = true,
  String? blockReason,
  String currencyCode = 'VND',
  Object listPriceMinor = 125000,
  Object? floorPriceMinor = 100000,
  Object? availableStockMicros = 12000000,
  List<Map<String, dynamic>>? units,
}) {
  return {
    'product_id': productId,
    'sku': sku,
    'display_name': displayName,
    'trade_name': tradeName,
    'is_sellable': isSellable,
    'block_reason': blockReason,
    'currency_code': currencyCode,
    'list_price_minor': listPriceMinor,
    'floor_price_minor': floorPriceMinor,
    'available_stock_micros': availableStockMicros,
    'units': units ?? [
      _unitJson(
        isSellable: isSellable,
        blockReason: blockReason,
        floorPriceMinor: floorPriceMinor,
        availableStockMicros: availableStockMicros,
      ),
    ],
  };
}

Map<String, dynamic> _unitJson({
  String unitId = _unitId,
  String unitCode = 'BOX',
  String unitName = 'Box',
  String? barcode = '8930000000001',
  bool isDefault = true,
  bool isActive = true,
  bool isSellable = true,
  String? blockReason,
  Object listPriceMinor = 125000,
  Object? floorPriceMinor = 100000,
  Object? availableStockMicros = 12000000,
}) {
  return {
    'product_unit_id': unitId,
    'unit_code': unitCode,
    'unit_name': unitName,
    'barcode': barcode,
    'is_default': isDefault,
    'is_active': isActive,
    'is_sellable': isSellable,
    'block_reason': blockReason,
    'list_price_minor': listPriceMinor,
    'floor_price_minor': floorPriceMinor,
    'available_stock_micros': availableStockMicros,
  };
}

typedef _RpcHandler = Future<dynamic> Function(Map<String, dynamic>? params);

final class _FakeCatalogSupabaseClient implements SupabaseClient {
  _FakeCatalogSupabaseClient(this._handlers);

  final Map<String, _RpcHandler> _handlers;
  final List<({String functionName, Map<String, dynamic>? params})> calls = [];

  @override
  SupabaseQuerySchema schema(String schema) {
    if (schema != 'catalog') {
      throw UnsupportedError('Only the catalog schema is supported.');
    }
    return _FakeCatalogQuerySchema(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakeCatalogQuerySchema implements SupabaseQuerySchema {
  _FakeCatalogQuerySchema(this._client);

  final _FakeCatalogSupabaseClient _client;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    bool get = false,
  }) => _FakeCatalogRpc<T>(_client, fn, params);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakeCatalogRpc<T> implements PostgrestFilterBuilder<T> {
  _FakeCatalogRpc(this._client, this._functionName, this._params);

  final _FakeCatalogSupabaseClient _client;
  final String _functionName;
  final Map<String, dynamic>? _params;

  @override
  Stream<T> asStream() => throw UnsupportedError('Streams are not supported.');

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _execute().then(onValue, onError: onError);
  }

  Future<T> _execute() async {
    _client.calls.add((functionName: _functionName, params: _params));
    final handler = _client._handlers[_functionName];
    if (handler == null) {
      return <String, dynamic>{} as T;
    }
    return await handler(_params) as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
