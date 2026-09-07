import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../../errors/einvoice_error_mapper.dart';
import 'i_einvoice_outbox_client.dart';

/// Supabase RPC client for claim / complete / fail on `einvoice.outbox_messages`.
///
/// Does **not** call `enqueue_outbox_message` — that helper is invoked from
/// mutation RPCs inside Postgres (same transaction as the business write).
final class SupabaseEinvoiceOutboxClient implements IEinvoiceOutboxClient {
  SupabaseEinvoiceOutboxClient({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<ClaimedOutboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'claim_outbox_batch',
        params: <String, dynamic>{'p_tenant_id': tenantId, 'p_limit': limit},
      );
      return rows
          .map(
            (row) => ClaimedOutboxMessage(
              messageId: row['message_id'].toString(),
              eventType: row['event_type'] as String,
              payload: Map<String, dynamic>.from(row['payload'] as Map),
              occurredAt: DateTime.parse(row['occurred_at'] as String),
              claimToken: row['claim_token'].toString(),
            ),
          )
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'complete_outbox_message',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_message_id': messageId,
          'p_claim_token': claimToken,
        },
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'fail_outbox_message',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_message_id': messageId,
          'p_claim_token': claimToken,
          'p_error': error,
        },
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
