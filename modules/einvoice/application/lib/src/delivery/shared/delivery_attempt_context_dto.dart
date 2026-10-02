final class DeliveryAttemptContextDto {
  const DeliveryAttemptContextDto({
    required this.tenantId,
    required this.deliveryId,
    required this.retryCount,
    required this.deliveryVersion,
    required this.providerConnectionId,
    required this.providerTransactionId,
    required this.invoiceSeries,
    required this.recipientEmail,
    this.recipientName,
  });

  final String tenantId;
  final String deliveryId;
  final int retryCount;
  final int deliveryVersion;
  final String providerConnectionId;
  final String providerTransactionId;
  final String invoiceSeries;
  final String recipientEmail;
  final String? recipientName;
}
