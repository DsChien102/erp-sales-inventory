export 'i_einvoice_internal_command_client.dart';

import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../../errors/einvoice_error_mapper.dart';
import 'i_einvoice_internal_command_client.dart';

/// Supabase RPC client for claim / complete / fail / retry on `einvoice.internal_commands`.
final class SupabaseEinvoiceInternalCommandClient
    implements IEinvoiceInternalCommandClient {
  SupabaseEinvoiceInternalCommandClient({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<int> seedDueReconciliationCommands({
    required String tenantId,
    int limit = 50,
  }) async {
    try {
      final result = await _rpcClient.callScalar<int>(
        'seed_due_issuance_reconciliation_commands',
        params: <String, dynamic>{'p_tenant_id': tenantId, 'p_limit': limit},
      );
      return result ?? 0;
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'claim_internal_commands_batch',
        params: <String, dynamic>{'p_tenant_id': tenantId, 'p_limit': limit},
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
              retryCount: (row['retry_count'] as num?)?.toInt() ?? 0,
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
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<InternalCommandDisposition> retryOrDeadLetter({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'retry_or_dead_letter_internal_command',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_command_id': commandId,
          'p_claim_token': claimToken,
          'p_error': error,
        },
      );
      if (rows.isEmpty) {
        throw RpcException(
          'retry_or_dead_letter_internal_command returned no rows',
        );
      }
      final dispositionRaw = rows.first['disposition'] as String?;
      return switch (dispositionRaw) {
        'DEAD_LETTER' => InternalCommandDisposition.deadLetter,
        'RETRY' => InternalCommandDisposition.retry,
        _ => throw RpcException('Unknown disposition: $dispositionRaw'),
      };
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
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
      throw mapEinvoiceRpcError(error);
    }
  }
}
