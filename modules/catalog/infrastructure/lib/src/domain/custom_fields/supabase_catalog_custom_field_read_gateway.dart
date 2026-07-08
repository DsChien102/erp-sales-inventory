import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'custom_field_rpc_mapper.dart';

final class SupabaseCatalogCustomFieldReadGateway
    implements ICatalogCustomFieldReadGateway {
  SupabaseCatalogCustomFieldReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProductCustomFieldSnapshotDto> getSnapshot({
    required String tenantId,
    required List<String> productIds,
    required bool includeInactiveValues,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'get_product_custom_field_snapshot',
        params: CustomFieldRpcMapper.getProductCustomFieldSnapshotParams(
          tenantId: tenantId,
          productIds: productIds,
          includeInactiveValues: includeInactiveValues,
        ),
      );

      return CustomFieldRpcMapper.snapshotFromJson(row);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
