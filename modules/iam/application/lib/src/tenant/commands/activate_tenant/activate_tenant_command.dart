import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_activation_result_dto.dart';

@RequiresPermission(IamPermissions.tenantActivate)
@RequiresTenant()
final class ActivateTenantCommand extends CommandBase<TenantActivationResultDto>
    implements ICommand<TenantActivationResultDto>, ITenantScopedCommand {
  ActivateTenantCommand({
    String? id,
    required this.tenantId,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : super(id);

  @override
  final String tenantId;
  final int expectedVersion;
  final String idempotencyKey;
}
