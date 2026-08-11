import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../../errors/iam_error_mapper.dart';
import 'i_iam_inbox_client.dart';

final class SupabaseIamInboxClient implements IIamInboxClient {
  SupabaseIamInboxClient({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<String> receive({
    required String tenantId,
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
    required DateTime occurredAt,
  }) async {
    try {
      final id = await _rpcClient.callScalar<String>(
        'receive_integration_event',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_message_id': messageId,
          'p_event_type': eventType,
          'p_payload': payload,
          'p_occurred_at': occurredAt.toUtc().toIso8601String(),
        },
      );
      return id ?? messageId;
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<List<ClaimedInboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'claim_inbox_batch',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_limit': limit,
        },
      );
      return rows
          .map(
            (row) => ClaimedInboxMessage(
              messageId: row['message_id'].toString(),
              eventType: row['event_type'] as String,
              payload: Map<String, dynamic>.from(row['payload'] as Map),
              occurredAt: DateTime.parse(row['occurred_at'] as String),
              claimToken: row['claim_token'].toString(),
            ),
          )
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
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
        'complete_inbox_message',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_message_id': messageId,
          'p_claim_token': claimToken,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
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
        'fail_inbox_message',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_message_id': messageId,
          'p_claim_token': claimToken,
          'p_error': error,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }
}
