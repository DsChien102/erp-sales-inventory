import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';

class StockPolicyRepository {
  final InventoryRpc _rpc;

  StockPolicyRepository({required InventoryRpc rpc}) : _rpc = rpc;

  /// Đọc chính sách tồn và danh sách sản phẩm.
  Future<StockPolicySnapshot> load() async {
    final res = await _rpc.query('get_stock_policy');
    return StockPolicySnapshot.fromJson(res);
  }

  /// Lưu danh sách thay đổi ngưỡng cảnh báo và mục tiêu.
  Future<int> saveThresholds({
    required String idempotencyKey,
    required int expectedRevision,
    required List<ThresholdChange> changes,
  }) async {
    final res = await _rpc.mutate(
      scope: 'stock_policy.thresholds',
      fn: 'save_stock_thresholds',
      idempotencyKey: idempotencyKey,
      params: {
        'p_expected_revision': expectedRevision,
        'p_lines': changes.map((c) => c.toJson()).toList(),
      },
    );
    return (res['revision'] as num?)?.toInt() ?? expectedRevision + 1;
  }

  /// Lưu chính sách cận hạn: số ngày mặc định và danh sách riêng.
  Future<int> saveNearExpiry({
    required String idempotencyKey,
    required int expectedRevision,
    required int? defaultDays,
    required List<NearExpiryOverride> overrides,
  }) async {
    final res = await _rpc.mutate(
      scope: 'stock_policy.near_expiry',
      fn: 'save_near_expiry_policy',
      idempotencyKey: idempotencyKey,
      params: {
        'p_expected_revision': expectedRevision,
        'p_default_days': defaultDays,
        'p_overrides': overrides.map((o) => o.toJson()).toList(),
      },
    );
    return (res['revision'] as num?)?.toInt() ?? expectedRevision + 1;
  }
}

