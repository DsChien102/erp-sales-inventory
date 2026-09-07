import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'issuance_rpc_mapper.dart';

final class SupabaseIssuanceReconciliationGateway
    implements IIssuanceReconciliationGateway {
  SupabaseIssuanceReconciliationGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ReconciliationCaseDto> openReconciliationCase({
    required String tenantId,
    required String attemptId,
    required String reason,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'open_reconciliation_case',
        params: IssuanceRpcMapper.openReconciliationCaseParams(
          tenantId: tenantId,
          attemptId: attemptId,
          reason: reason,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('open_reconciliation_case returned no rows');
      }
      return IssuanceRpcMapper.reconciliationCaseFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<ReconciliationPollContextDto?> claimReconciliationCase({
    required String tenantId,
    required String caseId,
    required String workerId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'claim_issuance_reconciliation_case',
        params: IssuanceRpcMapper.claimReconciliationCaseParams(
          tenantId: tenantId,
          caseId: caseId,
          workerId: workerId,
        ),
      );
      if (rows.isEmpty) {
        return null;
      }
      return IssuanceRpcMapper.reconciliationPollContextFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> recordPendingCheck({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required Duration nextDelay,
    required int checkSequence,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'record_reconciliation_pending',
        params: IssuanceRpcMapper.recordReconciliationPendingParams(
          tenantId: tenantId,
          caseId: caseId,
          claimToken: claimToken,
          nextDelaySeconds: nextDelay.inSeconds,
          checkSequence: checkSequence,
        ),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<ReconciliationCaseDto> resolveReconciliationCase({
    required String tenantId,
    required String caseId,
    required String outcome,
    Map<String, Object?>? evidence,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'resolve_reconciliation_case',
        params: IssuanceRpcMapper.resolveReconciliationCaseParams(
          tenantId: tenantId,
          caseId: caseId,
          outcome: outcome,
          evidence: evidence,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('resolve_reconciliation_case returned no rows');
      }
      return IssuanceRpcMapper.reconciliationCaseFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> markUnresolved({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required String reasonCode,
  }) async {
    await resolveReconciliationCase(
      tenantId: tenantId,
      caseId: caseId,
      outcome: 'UNRESOLVED',
      evidence: <String, Object?>{
        'claim_token': claimToken,
        'reason_code': reasonCode,
      },
    );
  }

  @override
  Future<RecoverInternalFinalizationResultDto> recoverFinalization({
    required String tenantId,
    required String attemptId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'recover_internal_finalization',
        params: IssuanceRpcMapper.recoverInternalFinalizationParams(
          tenantId: tenantId,
          attemptId: attemptId,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('recover_internal_finalization returned no rows');
      }
      return IssuanceRpcMapper.recoverInternalFinalizationResultFromRow(
        rows.first,
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<IssuanceAttemptStatusDto> getAttemptStatus({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_issuance_attempt_status',
        params: IssuanceRpcMapper.getIssuanceAttemptStatusParams(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('get_issuance_attempt_status returned no rows');
      }
      return IssuanceRpcMapper.issuanceAttemptStatusFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
