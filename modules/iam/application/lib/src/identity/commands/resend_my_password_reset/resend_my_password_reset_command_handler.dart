import 'package:vet45_shared_application/application.dart';

import '../../ports/i_identity_self_service_gateway.dart';
import '../../shared/password_reset_operation_dto.dart';
import 'resend_my_password_reset_command.dart';

@CommandHandlerFor(ResendMyPasswordResetCommand)
final class ResendMyPasswordResetCommandHandler
    implements
        ICommandHandler<ResendMyPasswordResetCommand, PasswordResetOperationDto> {
  ResendMyPasswordResetCommandHandler({
    required IIdentitySelfServiceGateway identityGateway,
  }) : _identityGateway = identityGateway;

  final IIdentitySelfServiceGateway _identityGateway;

  @override
  Future<PasswordResetOperationDto> handle(
    ResendMyPasswordResetCommand command,
  ) {
    return _identityGateway.resendMyPasswordReset(
      operationId: command.operationId.trim(),
    );
  }
}
