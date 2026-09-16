import 'package:vet45_shared_application/application.dart';

import 'start_auto_issuance_result.dart';

/// Internal — inbox handler on sales_order_finalized.v1.
@RequiresTenant()
final class StartAutoIssuanceCommand extends CommandBase<AutoIssuanceResultDto>
    implements ICommand<AutoIssuanceResultDto>, ITenantScopedCommand {
  StartAutoIssuanceCommand({
    String? id,
    required this.tenantId,
    required this.salesOrderId,
    required this.triggerKey,
    required this.idempotencyKey,
  }) : super(id);

  @override
  final String tenantId;
  final String salesOrderId;
  final String triggerKey;
  final String idempotencyKey;
}
