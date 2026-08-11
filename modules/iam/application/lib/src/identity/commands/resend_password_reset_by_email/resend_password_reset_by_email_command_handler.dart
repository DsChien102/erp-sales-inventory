import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_password_reset_public_port.dart';
import '../../shared/password_reset_request_result_dto.dart';
import 'resend_password_reset_by_email_command.dart';

@CommandHandlerFor(ResendPasswordResetByEmailCommand)
final class ResendPasswordResetByEmailCommandHandler
    implements
        ICommandHandler<
          ResendPasswordResetByEmailCommand,
          PasswordResetRequestResultDto
        > {
  ResendPasswordResetByEmailCommandHandler({
    required IPasswordResetPublicPort publicResetPort,
  }) : _publicResetPort = publicResetPort;

  final IPasswordResetPublicPort _publicResetPort;

  @override
  Future<PasswordResetRequestResultDto> handle(
    ResendPasswordResetByEmailCommand command,
  ) {
    return _publicResetPort.resend(operationId: command.operationId.trim());
  }
}
