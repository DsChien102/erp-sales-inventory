import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Suspend a Platform User (EP-01/US-02). Requires a reason (FR-04).
@RequiresPermission(IamPlatformPermissions.userSuspend)
@Idempotent(keyField: 'idempotencyKey')
final class SuspendPlatformUserCommand extends CommandBase<void>
    implements ICommand<void> {
  SuspendPlatformUserCommand({
    String? id,
    required this.userId,
    required this.reason,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : super(id);

  final String userId;
  final String reason;
  final int expectedVersion;
  final String idempotencyKey;
}
