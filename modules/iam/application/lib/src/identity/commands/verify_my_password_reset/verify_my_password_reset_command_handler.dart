import 'package:vet45_shared_application/application.dart';

import '../../ports/i_identity_self_service_gateway.dart';
import 'verify_my_password_reset_command.dart';

@CommandHandlerFor(VerifyMyPasswordResetCommand)
final class VerifyMyPasswordResetCommandHandler
    implements ICommandHandler<VerifyMyPasswordResetCommand, void> {
  VerifyMyPasswordResetCommandHandler({
    required IIdentitySelfServiceGateway identityGateway,
  }) : _identityGateway = identityGateway;

  final IIdentitySelfServiceGateway _identityGateway;

  @override
  Future<void> handle(VerifyMyPasswordResetCommand command) {
    return _identityGateway.verifyMyPasswordReset(
      operationId: command.operationId.trim(),
      code: command.code.trim(),
    );
  }
}
