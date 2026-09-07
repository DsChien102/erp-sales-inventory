import 'package:vet45_shared_application/application.dart';

import '../../shared/delivery_result_evidence.dart';
import 'record_delivery_result_result.dart';

@RequiresTenant()
final class RecordDeliveryResultCommand extends CommandBase<RecordDeliveryResultDto>
    implements ICommand<RecordDeliveryResultDto>, ITenantScopedCommand {
  RecordDeliveryResultCommand({
    String? id,
    required this.tenantId,
    required this.deliveryId,
    required this.attemptId,
    required this.expectedDeliveryVersion,
    required this.expectedAttemptVersion,
    required this.interactionReference,
    required this.evidence,
  }) : super(id);

  @override
  final String tenantId;
  final String deliveryId;
  final String attemptId;
  final int expectedDeliveryVersion;
  final int expectedAttemptVersion;
  final String interactionReference;
  final DeliveryResultEvidence evidence;
}
