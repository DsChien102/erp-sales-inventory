import 'package:vet45_shared_application/application.dart';

import 'record_delivery_result_result.dart';

@RequiresTenant()
final class RecordDeliveryResultCommand extends CommandBase<RecordDeliveryResultDto>
    implements ICommand<RecordDeliveryResultDto>, ITenantScopedCommand {
  RecordDeliveryResultCommand({
    String? id,
    required this.tenantId,
    required this.deliveryId,
    required this.attemptId,
    required this.providerResult,
  }) : super(id);

  @override
  final String tenantId;
  final String deliveryId;
  final String attemptId;
  final Map<String, Object?> providerResult;
}
