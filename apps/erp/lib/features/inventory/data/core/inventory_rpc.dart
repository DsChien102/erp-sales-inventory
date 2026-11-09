import 'package:erp/core/supabase/supabase_rpc.dart';

class InventoryRpc {
  InventoryRpc({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
  })  : _rpc = rpc,
        _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  /// Gọi RPC đọc trong schema `inventory`. Tự đính kèm `p_tenant_id`.
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async {
    final tId = await _tenantId();
    final mergedParams = <String, dynamic>{
      'p_tenant_id': tId,
      ...params,
    };

    final res = await _rpc.call('inventory', fn, params: mergedParams);
    if (res is Map<String, dynamic>) {
      return res;
    }
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return <String, dynamic>{};
  }

  /// Gọi RPC ghi trong schema `inventory`. Tự đính kèm `p_tenant_id` và `p_idempotency_key`.
  Future<Map<String, dynamic>> mutate({
    required String scope,
    required String idempotencyKey,
    required String fn,
    required Map<String, dynamic> params,
  }) async {
    final tId = await _tenantId();
    final mergedParams = <String, dynamic>{
      'p_tenant_id': tId,
      'p_idempotency_key': idempotencyKey,
      ...params,
    };

    final res = await _rpc.call('inventory', fn, params: mergedParams);
    if (res is Map<String, dynamic>) {
      return res;
    }
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return <String, dynamic>{};
  }
}
