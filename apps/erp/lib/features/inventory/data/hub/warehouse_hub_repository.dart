import '../core/inventory_rpc.dart';
import 'warehouse_hub_summary.dart';

class WarehouseHubRepository {
  const WarehouseHubRepository({required InventoryRpc rpc}) : _rpc = rpc;

  final InventoryRpc _rpc;

  Future<WarehouseHubSummary> getSummary() async {
    final res = await _rpc.query('get_warehouse_hub_summary');
    final activated = res['activated'] as bool? ?? false;
    return WarehouseHubSummary(
      activated: activated,
      problems: null,
    );
  }
}
