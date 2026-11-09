import 'warehouse_hub_summary.dart';

class WarehouseHubRepository {
  const WarehouseHubRepository();

  Future<WarehouseHubSummary> getSummary() async {
    // G5-0a trả giá trị cố định; G5-0b thay thân bằng RPC inventory.get_warehouse_hub_summary
    return const WarehouseHubSummary(activated: true);
  }
}
