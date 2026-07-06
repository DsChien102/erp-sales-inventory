import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_readiness_facts_mapper.dart';
import 'product_rpc_mapper.dart';

final class SupabaseProductReadinessReadGateway
    implements IProductReadinessReadPort {
  SupabaseProductReadinessReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProductReadinessFacts?> loadFacts({
    required String tenantId,
    required String productId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_product_readiness',
        params: ProductRpcMapper.getProductReadinessParams(
          tenantId: tenantId,
          productId: productId,
        ),
      );

      if (rows.isEmpty) {
        return null;
      }

      return ProductReadinessFactsMapper.fromRow(rows.first);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
