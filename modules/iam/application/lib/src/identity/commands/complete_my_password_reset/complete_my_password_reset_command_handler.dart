import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_authenticator.dart';
import '../../ports/i_identity_self_service_gateway.dart';
import 'complete_my_password_reset_command.dart';

@CommandHandlerFor(CompleteMyPasswordResetCommand)
final class CompleteMyPasswordResetCommandHandler
    implements ICommandHandler<CompleteMyPasswordResetCommand, void> {
  CompleteMyPasswordResetCommandHandler({
    required IAuthenticator authenticator,
    required IIdentitySelfServiceGateway identityGateway,
  }) : _authenticator = authenticator,
       _identityGateway = identityGateway;

  final IAuthenticator _authenticator;
  final IIdentitySelfServiceGateway _identityGateway;

  @override
  Future<void> handle(CompleteMyPasswordResetCommand command) async {
    // Credential write via GoTrue first — if this fails, operation stays open.
    await _authenticator.updatePassword(command.newPassword);
    await _identityGateway.completeMyPasswordReset(
      operationId: command.operationId.trim(),
      newPassword: command.newPassword,
    );
  }
}
