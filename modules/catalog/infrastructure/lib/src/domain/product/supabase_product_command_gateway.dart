import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_rpc_mapper.dart';

final class SupabaseProductCommandGateway implements IProductCommandGateway {
  SupabaseProductCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<String> create({
    required Product product,
    required String idempotencyKey,
  }) async {
    try {
      final productId = await _rpcClient.callScalar<String>(
        'create_product',
        params: ProductRpcMapper.createProductParams(
          product: product,
          idempotencyKey: idempotencyKey,
        ),
      );

      if (productId == null || productId.isEmpty) {
        throw ApplicationException('Product create did not return an id.');
      }

      return productId;
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<void> setInitialStock({
    required String productId,
    required String tenantId,
    required ProductStockProfile profile,
  }) async {
    try {
      await _rpcClient.callScalar<void>(
        'set_initial_stock',
        params: ProductRpcMapper.setInitialStockParams(
          productId: productId,
          tenantId: tenantId,
          profile: profile,
        ),
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<void> setManualBasePrice({
    required String productId,
    required String tenantId,
    required ProductBasePriceProfile profile,
  }) async {
    try {
      await _rpcClient.callScalar<void>(
        'set_manual_base_price',
        params: ProductRpcMapper.setManualBasePriceParams(
          productId: productId,
          tenantId: tenantId,
          profile: profile,
        ),
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<void> setInitialPriceBand({
    required String productId,
    required String tenantId,
    required ProductUnitPriceBand priceBand,
  }) async {
    try {
      await _rpcClient.callScalar<void>(
        'set_initial_price_band',
        params: ProductRpcMapper.setInitialPriceBandParams(
          productId: productId,
          tenantId: tenantId,
          priceBand: priceBand,
        ),
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
