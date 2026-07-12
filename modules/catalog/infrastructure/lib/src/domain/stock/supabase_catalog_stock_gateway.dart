import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import '../product/product_rpc_mapper.dart';

final class SupabaseCatalogStockGateway implements ICatalogStockGateway {
  SupabaseCatalogStockGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<AdjustBasicStockGatewayResult> adjustBasicStock({
    required AdjustBasicStockCommand command,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'adjust_basic_stock',
        params: ProductRpcMapper.adjustBasicStockParams(command),
      );

      if (row.isEmpty) {
        throw ApplicationException('Adjust basic stock did not return a result.');
      }

      return AdjustBasicStockGatewayResult(
        previousQuantity: (row['previous_quantity'] as num).toInt(),
        newQuantity: (row['new_quantity'] as num).toInt(),
        unitName: row['unit_name'] as String?,
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
