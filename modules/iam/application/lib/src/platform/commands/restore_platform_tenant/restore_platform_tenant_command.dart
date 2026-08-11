import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Restore a suspended Platform Tenant (EP-02/US-06).
@RequiresPermission(IamPlatformPermissions.tenantRestore)
@Idempotent(keyField: 'idempotencyKey')
final class RestorePlatformTenantCommand extends CommandBase<void>
    implements ICommand<void> {
  RestorePlatformTenantCommand({
    String? id,
    required this.tenantId,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : super(id);

  final String tenantId;
  final int expectedVersion;
  final String idempotencyKey;
}
