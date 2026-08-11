export 'i_iam_internal_command_client.dart';

import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../../errors/iam_error_mapper.dart';
import 'i_iam_internal_command_client.dart';

/// Supabase RPC client for claim / complete / fail on `iam.internal_commands`.
final class SupabaseIamInternalCommandClient
    implements IIamInternalCommandClient {
  SupabaseIamInternalCommandClient({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'claim_internal_commands_batch',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_limit': limit,
        },
      );
      return rows
          .map(
            (row) => ClaimedInternalCommand(
              commandId: row['command_id'].toString(),
              commandType: row['command_type'] as String,
              payload: Map<String, dynamic>.from(row['payload'] as Map),
              enqueuedAt: DateTime.parse(row['enqueued_at'] as String),
              claimToken: row['claim_token'].toString(),
              sourceEventId: row['source_event_id']?.toString(),
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
    required String commandId,
    required String claimToken,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'complete_internal_command',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_command_id': commandId,
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
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'fail_internal_command',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_command_id': commandId,
          'p_claim_token': claimToken,
          'p_error': error,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }
}
