import 'package:vet45_shared_application/application.dart';

import '../../ports/i_platform_admin_gateway.dart';
import 'send_activation_invitation_command.dart';

@CommandHandlerFor(SendActivationInvitationCommand)
final class SendActivationInvitationCommandHandler
    implements ICommandHandler<SendActivationInvitationCommand, void> {
  SendActivationInvitationCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<void> handle(SendActivationInvitationCommand command) {
    return _platformGateway.sendActivationInvitation(command.userId);
  }
}
