import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Initiate password-reset via Platform Identity (EP-01/US-02).
///
/// Does **not** return credentials to the Platform Admin (BR-01 / BR-02).
@RequiresPermission(IamPlatformPermissions.userPasswordResetInitiate)
@Idempotent(keyField: 'idempotencyKey')
final class RequestPlatformPasswordResetCommand extends CommandBase<void>
    implements ICommand<void> {
  RequestPlatformPasswordResetCommand({
    String? id,
    required this.userId,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : super(id);

  final String userId;
  final int expectedVersion;
  final String idempotencyKey;
}
