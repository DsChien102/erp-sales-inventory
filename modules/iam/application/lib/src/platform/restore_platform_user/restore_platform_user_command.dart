import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Restore a suspended Platform User (EP-01/US-02).
@RequiresPermission(IamPlatformPermissions.userRestore)
@Idempotent(keyField: 'idempotencyKey')
final class RestorePlatformUserCommand extends CommandBase<void>
    implements ICommand<void> {
  RestorePlatformUserCommand({
    String? id,
    required this.userId,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : super(id);

  final String userId;
  final int expectedVersion;
  final String idempotencyKey;
}
