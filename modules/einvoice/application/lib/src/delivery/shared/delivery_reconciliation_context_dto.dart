final class DeliveryReconciliationContextDto {
  const DeliveryReconciliationContextDto({
    required this.tenantId,
    required this.reconciliationCaseId,
    required this.deliveryId,
    required this.providerConnectionId,
    required this.supportsDeliveryResultObservation,
    required this.checkSequence,
    required this.caseVersion,
    this.providerDeliveryReference,
  });

  final String tenantId;
  final String reconciliationCaseId;
  final String deliveryId;
  final String providerConnectionId;
  final bool supportsDeliveryResultObservation;
  final int checkSequence;
  final int caseVersion;
  final String? providerDeliveryReference;
}
