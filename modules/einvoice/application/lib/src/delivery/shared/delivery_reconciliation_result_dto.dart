import 'package:vet45_einvoice_domain/domain.dart';

final class DeliveryReconciliationResultDto {
  const DeliveryReconciliationResultDto({
    required this.caseStatus,
    required this.deliveryStatus,
    required this.hasSecondaryAttention,
    this.nextCheckAt,
  });

  final ReconciliationCaseStatus caseStatus;
  final DeliveryStatus deliveryStatus;
  final DateTime? nextCheckAt;
  final bool hasSecondaryAttention;
}
