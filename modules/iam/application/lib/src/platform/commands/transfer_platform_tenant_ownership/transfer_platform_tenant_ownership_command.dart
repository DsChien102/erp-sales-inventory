import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Transfer Platform Tenant ownership atomically (EP-02/US-09).
@RequiresPermission(IamPlatformPermissions.tenantOwnerTransfer)
@Idempotent(keyField: 'idempotencyKey')
final class TransferPlatformTenantOwnershipCommand extends CommandBase<void>
    implements ICommand<void> {
  TransferPlatformTenantOwnershipCommand({
    String? id,
    required this.tenantId,
    required this.newOwnerUserId,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : super(id);

  final String tenantId;
  final String newOwnerUserId;
  final int expectedVersion;
  final String idempotencyKey;
}
