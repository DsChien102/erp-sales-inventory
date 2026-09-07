import 'delivery_result_evidence.dart';

final class DeliveryResultRecord {
  const DeliveryResultRecord({
    required this.tenantId,
    required this.deliveryId,
    required this.attemptId,
    required this.expectedDeliveryVersion,
    required this.expectedAttemptVersion,
    required this.interactionReference,
    required this.evidence,
  });

  final String tenantId;
  final String deliveryId;
  final String attemptId;
  final int expectedDeliveryVersion;
  final int expectedAttemptVersion;
  final String interactionReference;
  final DeliveryResultEvidence evidence;
}
