import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_stock_mapper.dart';
import '../product/product_rpc_mapper.dart';

final class SupabaseProductStockReadGateway implements IProductStockReadPort {
  SupabaseProductStockReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<ProductStockMovementReadRow>> listMovements({
    required String tenantId,
    required String productId,
    int limit = 50,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_product_stock_history',
        params: ProductRpcMapper.getProductStockHistoryParams(
          tenantId: tenantId,
          productId: productId,
          limit: limit,
        ),
      );

      return rows
          .map(ProductStockMapper.movementReadRowFromRpc)
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
