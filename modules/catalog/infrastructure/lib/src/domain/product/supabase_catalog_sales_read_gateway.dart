import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'catalog_sales_lookup_rpc_mapper.dart';

final class SupabaseCatalogSalesReadGateway implements ICatalogSalesReadGateway {
  SupabaseCatalogSalesReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<SellableProductDto>> searchSellableProducts({
    required String tenantId,
    required String storeId,
    required String keyword,
    required int limit,
    required int offset,
  }) async {
    try {
      final payload = await _rpcClient.callScalar<Object?>(
        'search_sellable_products',
        params: CatalogSalesLookupRpcMapper.searchSellableProductsParams(
          tenantId: tenantId,
          storeId: storeId,
          keyword: keyword,
          limit: limit,
          offset: offset,
        ),
      );
      return CatalogSalesLookupRpcMapper.productsFromPayload(payload);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<List<SellableProductDto>> resolveSellableBarcode({
    required String tenantId,
    required String storeId,
    required String barcode,
  }) async {
    try {
      final payload = await _rpcClient.callScalar<Object?>(
        'resolve_sellable_barcode',
        params: CatalogSalesLookupRpcMapper.resolveSellableBarcodeParams(
          tenantId: tenantId,
          storeId: storeId,
          barcode: barcode,
        ),
      );
      return CatalogSalesLookupRpcMapper.productsFromPayload(payload);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<List<SellableProductUnitDto>> listSellableProductUnits({
    required String tenantId,
    required String storeId,
    required String productId,
  }) async {
    try {
      final payload = await _rpcClient.callScalar<Object?>(
        'list_sellable_product_units',
        params: CatalogSalesLookupRpcMapper.listSellableProductUnitsParams(
          tenantId: tenantId,
          storeId: storeId,
          productId: productId,
        ),
      );
      return CatalogSalesLookupRpcMapper.unitsFromPayload(payload);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<List<SellableProductResolutionDto>> resolveSellableProducts({
    required String tenantId,
    required String storeId,
    required List<String> productIds,
  }) async {
    try {
      final payload = await _rpcClient.callScalar<Object?>(
        'resolve_sellable_products',
        params: CatalogSalesLookupRpcMapper.resolveSellableProductsParams(
          tenantId: tenantId,
          storeId: storeId,
          productIds: productIds,
        ),
      );
      return CatalogSalesLookupRpcMapper.resolutionsFromPayload(payload);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
