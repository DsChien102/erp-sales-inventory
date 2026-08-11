import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_password_reset_public_port.dart';
import '../../shared/password_reset_request_result_dto.dart';
import 'request_password_reset_by_email_command.dart';

@CommandHandlerFor(RequestPasswordResetByEmailCommand)
final class RequestPasswordResetByEmailCommandHandler
    implements
        ICommandHandler<
          RequestPasswordResetByEmailCommand,
          PasswordResetRequestResultDto
        > {
  RequestPasswordResetByEmailCommandHandler({
    required IPasswordResetPublicPort publicResetPort,
  }) : _publicResetPort = publicResetPort;

  final IPasswordResetPublicPort _publicResetPort;

  @override
  Future<PasswordResetRequestResultDto> handle(
    RequestPasswordResetByEmailCommand command,
  ) {
    return _publicResetPort.requestByEmail(email: command.email.trim());
  }
}
