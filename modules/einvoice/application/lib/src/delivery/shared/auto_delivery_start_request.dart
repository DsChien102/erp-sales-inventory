final class AutoDeliveryStartRequest {
  const AutoDeliveryStartRequest({
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.triggerId,
    required this.idempotencyKey,
  });

  final String tenantId;
  final String electronicInvoiceId;
  final String triggerId;
  final String idempotencyKey;
}
