import 'delivery_result_evidence.dart';

final class DeliveryResultRecord {
  const DeliveryResultRecord({
    required this.tenantId,
    required this.deliveryId,
    required this.retryCount,
    required this.expectedDeliveryVersion,
    required this.evidence,
  });

  final String tenantId;
  final String deliveryId;
  final int retryCount;
  final int expectedDeliveryVersion;
  final DeliveryResultEvidence evidence;
}
