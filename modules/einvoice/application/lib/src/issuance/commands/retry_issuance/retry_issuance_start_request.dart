final class RetryIssuanceStartRequest {
  const RetryIssuanceStartRequest({
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
    required this.expectedOrderVersion,
    required this.idempotencyKey,
    required this.acknowledgeWarnings,
  });

  final String tenantId;
  final String actorId;
  final String salesOrderId;
  final int expectedOrderVersion;
  final String idempotencyKey;
  final bool acknowledgeWarnings;
}
