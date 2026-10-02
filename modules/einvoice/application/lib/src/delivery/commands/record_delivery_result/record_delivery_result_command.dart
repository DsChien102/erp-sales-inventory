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
    required this.retryCount,
    required this.expectedDeliveryVersion,
    required this.evidence,
  }) : super(id);

  @override
  final String tenantId;
  final String deliveryId;
  final int retryCount;
  final int expectedDeliveryVersion;
  final DeliveryResultEvidence evidence;
}
