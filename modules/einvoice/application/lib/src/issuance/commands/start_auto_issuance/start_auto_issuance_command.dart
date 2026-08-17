import 'package:vet45_shared_application/application.dart';

import 'start_auto_issuance_result.dart';

/// Internal — inbox handler on sales.order.completed.
@RequiresTenant()
final class StartAutoIssuanceCommand extends CommandBase<AutoIssuanceResultDto>
    implements ICommand<AutoIssuanceResultDto>, ITenantScopedCommand {
  StartAutoIssuanceCommand({
    String? id,
    required this.tenantId,
    required this.salesOrderId,
    required this.triggerId,
    required this.idempotencyKey,
  }) : super(id);

  @override
  final String tenantId;
  final String salesOrderId;
  final String triggerId;
  final String idempotencyKey;
}
