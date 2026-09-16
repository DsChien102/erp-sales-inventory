/// Read-only snapshot of a claimed reconciliation case for polling.
final class ReconciliationPollContextDto {
  const ReconciliationPollContextDto({
    required this.caseId,
    required this.attemptId,
    required this.claimToken,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.invoiceSeries,
    this.providerReference,
    this.reconciliationReasonCode,
    required this.checkSequence,
    required this.maxChecks,
  });

  final String caseId;
  final String attemptId;
  final String claimToken;
  final String idempotencyKey;
  final String payloadHash;
  final String invoiceSeries;
  final String? providerReference;
  final String? reconciliationReasonCode;
  final int checkSequence;
  final int maxChecks;
}
