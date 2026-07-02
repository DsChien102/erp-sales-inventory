export 'i_partner_inbox_client.dart';

import '../partner_schema_rpc.dart';
import 'i_partner_inbox_client.dart';

/// Supabase-backed `partner.inbox_messages` queue (claim-token contract).
final class SupabasePartnerInboxClient implements IPartnerInboxClient {
  SupabasePartnerInboxClient({required PartnerSchemaRpc rpcClient})
      : _rpcClient = rpcClient;

  final PartnerSchemaRpc _rpcClient;

  @override
  Future<List<PartnerInboxMessage>> claimBatch({
    required String tenantId,
    int batchSize = 10,
  }) async {
    final rows = await _rpcClient.callList(
      'claim_inbox_batch',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_limit': batchSize,
      },
    );

    return rows
        .map(
          (row) => PartnerInboxMessage(
            messageId: row['message_id'] as String,
            claimToken: row['claim_token'] as String,
            eventType: row['event_type'] as String,
            payload: Map<String, dynamic>.from(row['payload'] as Map),
            occurredOn: DateTime.parse(row['occurred_at'] as String),
          ),
        )
        .toList();
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) {
    return _rpcClient.callScalar<void>(
      'complete_inbox_message',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_message_id': messageId,
        'p_claim_token': claimToken,
      },
    );
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) {
    return _rpcClient.callScalar<void>(
      'fail_inbox_message',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_message_id': messageId,
        'p_claim_token': claimToken,
        'p_error': error,
      },
    );
  }
}
