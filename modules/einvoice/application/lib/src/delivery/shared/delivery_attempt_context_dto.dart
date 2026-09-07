final class DeliveryAttemptContextDto {
  const DeliveryAttemptContextDto({
    required this.tenantId,
    required this.deliveryId,
    required this.attemptId,
    required this.deliveryVersion,
    required this.attemptVersion,
    required this.providerConnectionId,
    required this.providerTransactionId,
    required this.invoiceSeries,
    required this.recipientEmail,
    this.recipientName,
  });

  final String tenantId;
  final String deliveryId;
  final String attemptId;
  final int deliveryVersion;
  final int attemptVersion;
  final String providerConnectionId;
  final String providerTransactionId;
  final String invoiceSeries;
  final String recipientEmail;
  final String? recipientName;
}
