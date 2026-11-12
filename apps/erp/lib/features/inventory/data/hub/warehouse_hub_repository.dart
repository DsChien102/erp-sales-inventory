import '../core/inventory_rpc.dart';
import 'warehouse_hub_summary.dart';

class WarehouseHubRepository {
  const WarehouseHubRepository({required InventoryRpc rpc}) : _rpc = rpc;

  final InventoryRpc _rpc;

  Future<WarehouseHubSummary> getSummary() async {
    final res = await _rpc.query('get_warehouse_hub_summary');
    final activated = res['activated'] as bool? ?? false;
    WarehouseAttention? problems;
    var openStocktakes = 0;
    var programsReached = 0;

    final rawProblems = res['problems'];
    if (activated && rawProblems is Map) {
      final map = Map<String, dynamic>.from(rawProblems);
      openStocktakes = (map['stocktakes_open'] as num?)?.toInt() ?? 0;
      programsReached = (map['programs_reached'] as num?)?.toInt() ?? 0;
      final products = (map['products'] as num?)?.toInt() ?? 0;
      if (products > 0) {
        final out = (map['out'] as num?)?.toInt() ?? 0;
        final low = (map['low'] as num?)?.toInt() ?? 0;
        final expired = (map['expired'] as num?)?.toInt() ?? 0;
        final nearExpiry = (map['near_expiry'] as num?)?.toInt() ?? 0;

        final parts = <String>[
          if (out > 0) '$out hết hàng',
          if (low > 0) '$low tồn thấp',
          if (expired > 0) '$expired có lô hết hạn',
          if (nearExpiry > 0) '$nearExpiry có lô cận hạn',
        ];
        problems = WarehouseAttention(
          count: products,
          text: parts.join(' · '),
        );
      }
    }

    return WarehouseHubSummary(
      activated: activated,
      problems: problems,
      openStocktakes: openStocktakes,
      programsReached: programsReached,
    );
  }
}
