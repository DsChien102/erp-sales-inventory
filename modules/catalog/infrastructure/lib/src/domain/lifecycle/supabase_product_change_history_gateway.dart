import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_change_history_rpc_mapper.dart';

final class SupabaseProductChangeHistoryGateway
    implements IProductChangeHistoryGateway {
  SupabaseProductChangeHistoryGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProductChangeHistoryPage> listHistory({
    required String tenantId,
    required String productId,
    required int limit,
    required int offset,
    List<ProductChangeCategory> changeCategories = const [],
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'get_product_change_history',
        params: ProductChangeHistoryRpcMapper.getProductChangeHistoryParams(
          tenantId: tenantId,
          productId: productId,
          limit: limit,
          offset: offset,
          changeCategories: changeCategories,
        ),
      );

      return ProductChangeHistoryRpcMapper.pageFromJson(json);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
