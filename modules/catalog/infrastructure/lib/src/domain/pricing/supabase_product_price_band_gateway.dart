import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_price_band_rpc_mapper.dart';

final class SupabaseProductPriceBandGateway implements IProductPriceBandGateway {
  SupabaseProductPriceBandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProductUnitPriceBandsDto> listProductUnitPriceBands({
    required String tenantId,
    required String productId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'list_product_unit_price_bands',
        params: ProductPriceBandRpcMapper.listProductUnitPriceBandsParams(
          tenantId: tenantId,
          productId: productId,
        ),
      );
      if (rows.isEmpty) {
        throw ApplicationException('Product unit price bands did not return a result.');
      }
      return ProductPriceBandRpcMapper.bandsFromRows(rows);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<void> setProductUnitPriceBand({
    required String tenantId,
    required String productId,
    required String productUnitId,
    required double listPrice,
    required double floorPrice,
    required PriceBandSourceType sourceType,
    String? storePriceRuleId,
  }) async {
    try {
      await _rpcClient.callList(
        'set_product_unit_price_band',
        params: ProductPriceBandRpcMapper.setProductUnitPriceBandParams(
          tenantId: tenantId,
          productId: productId,
          productUnitId: productUnitId,
          listPrice: listPrice,
          floorPrice: floorPrice,
          sourceType: sourceType,
          storePriceRuleId: storePriceRuleId,
        ),
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
