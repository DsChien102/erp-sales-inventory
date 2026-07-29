import 'package:vet45_shared_application/application.dart';

import '../../ports/i_identity_self_service_gateway.dart';
import 'complete_my_password_reset_command.dart';

@CommandHandlerFor(CompleteMyPasswordResetCommand)
final class CompleteMyPasswordResetCommandHandler
    implements ICommandHandler<CompleteMyPasswordResetCommand, void> {
  CompleteMyPasswordResetCommandHandler({
    required IIdentitySelfServiceGateway identityGateway,
  }) : _identityGateway = identityGateway;

  final IIdentitySelfServiceGateway _identityGateway;

  @override
  Future<void> handle(CompleteMyPasswordResetCommand command) {
    return _identityGateway.completeMyPasswordReset(
      operationId: command.operationId.trim(),
      newPassword: command.newPassword,
    );
  }
}
