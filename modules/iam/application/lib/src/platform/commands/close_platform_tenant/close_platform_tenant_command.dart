import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Close a Platform Tenant permanently (terminal). Requires a reason.
@RequiresPermission(IamPlatformPermissions.tenantClose)
@Idempotent(keyField: 'idempotencyKey')
final class ClosePlatformTenantCommand extends CommandBase<void> implements ICommand<void> {
  ClosePlatformTenantCommand({
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
