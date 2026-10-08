import 'package:erp/core/supabase/supabase_rpc.dart';

import 'models/partner_action_log.dart';

class PartnerRepository {
  PartnerRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
  }) : _rpc = rpc,
       _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  Future<PartnerActionLogPage> getActionLogs(
    String partnerId, {
    int page = 1,
    int limit = 20,
  }) async {
    final row = await _rpc.firstRow(
      'partner',
      'get_partner_action_logs',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_partner_id': partnerId,
        'p_page': page,
        'p_limit': limit,
      },
    );
    return PartnerActionLogPage.fromJson(row);
  }
}
