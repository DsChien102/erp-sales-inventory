import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/inventory_error_mapper.dart';

final class DefaultStoreWarehousePairGateway implements IDefaultStoreWarehousePairPort {
  DefaultStoreWarehousePairGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<EnsureDefaultStoreWarehousePairResultDto> ensure({
    required String tenantId,
    required String correlationId,
  }) async {
    final row = await _call('ensure_default_store_warehouse_pair', {
      'p_tenant_id': tenantId,
      'p_correlation_id': correlationId,
    });
    return EnsureDefaultStoreWarehousePairResultDto(
      storeId: row['storeId'] as String,
      storeName: row['storeName'] as String,
      warehouseId: row['warehouseId'] as String,
      warehouseName: row['warehouseName'] as String,
      replayed: row['replayed'] as bool,
    );
  }

  @override
  Future<DefaultStoreWarehousePairDto> get({required String tenantId}) async {
    final row = await _call('get_default_store_warehouse_pair', {
      'p_tenant_id': tenantId,
    });
    return DefaultStoreWarehousePairDto(
      storeId: row['storeId'] as String,
      storeName: row['storeName'] as String,
      warehouseId: row['warehouseId'] as String,
      warehouseName: row['warehouseName'] as String,
    );
  }

  @override
  Future<void> matches({
    required String tenantId,
    required String storeId,
    required String warehouseId,
  }) async {
    final pair = await get(tenantId: tenantId);
    if (pair.storeId != storeId || pair.warehouseId != warehouseId) {
      throw const ApplicationException('DEFAULT_PAIR_MISMATCH');
    }
  }

  Future<Map<String, dynamic>> _call(
    String functionName,
    Map<String, dynamic> params,
  ) async {
    try {
      return await _rpcClient.callMap(functionName, params: params);
    } on RpcException catch (error) {
      throw mapInventoryRpcError(error);
    }
  }
}
