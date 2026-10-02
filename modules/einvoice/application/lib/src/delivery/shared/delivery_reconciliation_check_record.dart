import 'delivery_observation_kind.dart';

final class DeliveryReconciliationCheckRecord {
  const DeliveryReconciliationCheckRecord({
    required this.tenantId,
    required this.reconciliationCaseId,
    required this.expectedCaseVersion,
    required this.checkSequence,
    required this.kind,
    this.providerReference,
    this.safeCode,
  });

  final String tenantId;
  final String reconciliationCaseId;
  final int expectedCaseVersion;
  final int checkSequence;
  final DeliveryObservationKind kind;
  final String? providerReference;
  final String? safeCode;
}
