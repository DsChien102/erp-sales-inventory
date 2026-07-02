export 'i_partner_internal_command_client.dart';

import '../partner_schema_rpc.dart';
import 'i_partner_internal_command_client.dart';

/// Supabase-backed `partner.internal_commands` queue (claim-token contract).
final class SupabasePartnerInternalCommandClient
    implements IPartnerInternalCommandClient {
  SupabasePartnerInternalCommandClient({required PartnerSchemaRpc rpcClient})
      : _rpcClient = rpcClient;

  final PartnerSchemaRpc _rpcClient;

  @override
  Future<List<PartnerInternalCommandRow>> claimBatch({
    required String tenantId,
    int batchSize = 10,
  }) async {
    final rows = await _rpcClient.callList(
      'claim_internal_commands_batch',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_limit': batchSize,
      },
    );

    return rows
        .map(
          (row) => PartnerInternalCommandRow(
            commandId: row['command_id'] as String,
            claimToken: row['claim_token'] as String,
            commandType: row['command_type'] as String,
            payload: Map<String, dynamic>.from(row['payload'] as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) {
    return _rpcClient.callScalar<void>(
      'complete_internal_command',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_command_id': commandId,
        'p_claim_token': claimToken,
      },
    );
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) {
    return _rpcClient.callScalar<void>(
      'fail_internal_command',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_command_id': commandId,
        'p_claim_token': claimToken,
        'p_error': error,
      },
    );
  }
}
