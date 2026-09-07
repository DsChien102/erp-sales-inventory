final class ManualDeliveryStartRequest {
  const ManualDeliveryStartRequest({
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
    required this.recipientEmail,
    required this.idempotencyKey,
  });

  final String tenantId;
  final String actorId;
  final String salesOrderId;
  final String recipientEmail;
  final String idempotencyKey;
}
