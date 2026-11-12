import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';

class CostingRepository {
  CostingRepository({required InventoryRpc rpc}) : _rpc = rpc;

  final InventoryRpc _rpc;

  Future<CostOverview> overview() async {
    final res = await _rpc.query('get_cost_overview');
    return CostOverview.fromJson(res);
  }

  Future<({CostMethod method, bool methodLocked})> setPolicy({
    required String idempotencyKey,
    required CostMethod method,
  }) async {
    final res = await _rpc.mutate(
      scope: 'cost_policy.set',
      idempotencyKey: idempotencyKey,
      fn: 'set_cost_policy',
      params: {'p_method': costMethodToWire(method)},
    );
    return (
      method: costMethodFromWire(res['method'] as String?),
      methodLocked: res['method_locked'] as bool? ?? false,
    );
  }

  Future<CostRunView> createRun({
    required String idempotencyKey,
    required CostRunKind kind,
  }) async {
    final res = await _rpc.mutate(
      scope: 'cost_run.create',
      idempotencyKey: idempotencyKey,
      fn: 'create_cost_run',
      params: {'p_kind': kind.wire},
    );
    return CostRunView.fromJson(res);
  }

  Future<CostRunView> getRun(String runId) async {
    final res = await _rpc.query('get_cost_run', {'p_run_id': runId});
    return CostRunView.fromJson(res);
  }

  Future<CostRunView> publish({
    required String idempotencyKey,
    required String runId,
  }) async {
    final res = await _rpc.mutate(
      scope: 'cost_run.publish',
      idempotencyKey: idempotencyKey,
      fn: 'publish_cost_run',
      params: {'p_run_id': runId},
    );
    return CostRunView.fromJson(res);
  }

  Future<void> discard({
    required String idempotencyKey,
    required String runId,
  }) async {
    await _rpc.mutate(
      scope: 'cost_run.discard',
      idempotencyKey: idempotencyKey,
      fn: 'discard_cost_run',
      params: {'p_run_id': runId},
    );
  }

  Future<CostVersionList> versions(String productId) async {
    final res = await _rpc.query(
      'list_cost_versions',
      {'p_product_id': productId},
    );
    return CostVersionList.fromJson(res);
  }
}

