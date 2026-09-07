import 'delivery_observation_kind.dart';

final class DeliveryReconciliationCheckRecord {
  const DeliveryReconciliationCheckRecord({
    required this.tenantId,
    required this.reconciliationCaseId,
    required this.expectedCaseVersion,
    required this.checkSequence,
    required this.kind,
    this.interactionReference,
    this.providerReference,
    this.safeCode,
  });

  final String tenantId;
  final String reconciliationCaseId;
  final int expectedCaseVersion;
  final int checkSequence;
  final String? interactionReference;
  final DeliveryObservationKind kind;
  final String? providerReference;
  final String? safeCode;
}
