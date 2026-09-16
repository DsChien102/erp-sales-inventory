import 'package:vet45_adapters/vet45_adapters.dart';

import 'i_sales_outbox_client.dart';

/// Supabase RPC client for claim / complete / fail on `sales.outbox_messages`.
///
/// Does **not** call `enqueue_outbox_message` — that helper is invoked from
/// mutation RPCs inside Postgres (same transaction as the business write).
final class SupabaseSalesOutboxClient implements ISalesOutboxClient {
  SupabaseSalesOutboxClient({required SupabaseSchemaRpcClient rpcClient}) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<ClaimedSalesOutboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final rows = await _rpcClient.callList(
      'claim_outbox_batch',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_limit': limit,
      },
    );
    return rows
        .map(
          (row) => ClaimedSalesOutboxMessage(
            messageId: row['message_id'].toString(),
            eventType: row['event_type'] as String,
            payload: Map<String, dynamic>.from(row['payload'] as Map),
            occurredAt: DateTime.parse(row['occurred_at'] as String),
            claimToken: row['claim_token'].toString(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {
    await _rpcClient.callScalar<Object?>(
      'complete_outbox_message',
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
  }) async {
    await _rpcClient.callScalar<Object?>(
      'fail_outbox_message',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_message_id': messageId,
        'p_claim_token': claimToken,
        'p_error': error,
      },
    );
  }
}
