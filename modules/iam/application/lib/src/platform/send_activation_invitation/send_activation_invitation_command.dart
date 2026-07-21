import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Resend activation invitation for a pending Platform User (EP-01/US-02).
@RequiresPermission(IamPlatformPermissions.userActivationInviteSend)
final class SendActivationInvitationCommand extends CommandBase<void>
    implements ICommand<void> {
  SendActivationInvitationCommand({
    String? id,
    required this.userId,
  }) : super(id);

  final String userId;
}
