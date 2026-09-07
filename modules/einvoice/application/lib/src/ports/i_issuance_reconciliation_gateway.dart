import '../issuance/commands/recover_internal_finalization/recover_internal_finalization_result.dart';
import '../issuance/queries/get_issuance_attempt_status/issuance_attempt_status_dto.dart';
import '../issuance/shared/reconciliation_case_dto.dart';
import '../issuance/shared/reconciliation_poll_context_dto.dart';

/// Port for opening, claiming, resolving, and status recovery for reconciliation cases.
abstract interface class IIssuanceReconciliationGateway {
  Future<ReconciliationCaseDto> openReconciliationCase({
    required String tenantId,
    required String attemptId,
    required String reason,
  });

  Future<ReconciliationPollContextDto?> claimReconciliationCase({
    required String tenantId,
    required String caseId,
    required String workerId,
  });

  Future<void> recordPendingCheck({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required Duration nextDelay,
    required int checkSequence,
  });

  Future<ReconciliationCaseDto> resolveReconciliationCase({
    required String tenantId,
    required String caseId,
    required String outcome,
    Map<String, Object?>? evidence,
  });

  Future<void> markUnresolved({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required String reasonCode,
  });

  Future<RecoverInternalFinalizationResultDto> recoverFinalization({
    required String tenantId,
    required String attemptId,
  });

  Future<IssuanceAttemptStatusDto> getAttemptStatus({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });
}
