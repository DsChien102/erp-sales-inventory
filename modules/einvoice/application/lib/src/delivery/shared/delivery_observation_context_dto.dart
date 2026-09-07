final class DeliveryObservationContextDto {
  const DeliveryObservationContextDto({
    required this.tenantId,
    required this.reconciliationCaseId,
    required this.deliveryId,
    required this.attemptId,
    required this.providerConnectionId,
    this.providerDeliveryReference,
  });

  final String tenantId;
  final String reconciliationCaseId;
  final String deliveryId;
  final String attemptId;
  final String providerConnectionId;
  final String? providerDeliveryReference;
}
