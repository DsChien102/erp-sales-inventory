final class DeliveryProviderContextDto {
  const DeliveryProviderContextDto({
    required this.tenantId,
    required this.providerConnectionId,
    required this.providerTransactionId,
    required this.invoiceSeries,
    required this.recipientEmail,
    this.recipientName,
  });

  final String tenantId;
  final String providerConnectionId;
  final String providerTransactionId;
  final String invoiceSeries;
  final String recipientEmail;
  final String? recipientName;
}
