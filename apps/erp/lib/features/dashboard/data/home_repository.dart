import '../../../core/supabase/supabase_rpc.dart';
import 'models/home_summary.dart';

/// Trang chủ: một lần gọi `sales.get_home_summary` trả cả màn (10-8b).
class HomeRepository {
  HomeRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
  }) : _rpc = rpc,
       _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  Future<HomeSummary> fetch() async {
    final tenant = await _tenantId();
    final row = await _rpc.call(
      'sales',
      'get_home_summary',
      params: {'p_tenant_id': tenant},
    );
    return HomeSummary.fromJson(Map<String, dynamic>.from(row as Map));
  }
}
