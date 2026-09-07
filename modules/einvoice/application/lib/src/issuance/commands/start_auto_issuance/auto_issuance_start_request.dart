final class AutoIssuanceStartRequest {
  const AutoIssuanceStartRequest({
    required this.tenantId,
    required this.salesOrderId,
    required this.triggerKey,
    required this.idempotencyKey,
  });

  final String tenantId;
  final String salesOrderId;
  final String triggerKey;
  final String idempotencyKey;
}
