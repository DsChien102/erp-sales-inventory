import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Suspend a Platform Tenant (EP-02/US-06). Requires a reason (FR-03).
@RequiresPermission(IamPlatformPermissions.tenantSuspend)
@Idempotent(keyField: 'idempotencyKey')
final class SuspendPlatformTenantCommand extends CommandBase<void>
    implements ICommand<void> {
  SuspendPlatformTenantCommand({
    String? id,
    required this.tenantId,
    required this.reason,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : super(id);

  final String tenantId;
  final String reason;
  final int expectedVersion;
  final String idempotencyKey;
}
