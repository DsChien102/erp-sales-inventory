final class IssueInvoiceStartRequest {
  const IssueInvoiceStartRequest({
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
    required this.sourceVersion,
    required this.idempotencyKey,
    required this.acknowledgeWarnings,
  });

  final String tenantId;
  final String actorId;
  final String salesOrderId;
  final String sourceVersion;
  final String idempotencyKey;
  final bool acknowledgeWarnings;
}
