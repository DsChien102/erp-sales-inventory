import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_password_reset_public_port.dart';
import '../../shared/password_reset_verify_result_dto.dart';
import 'verify_password_reset_by_email_command.dart';

@CommandHandlerFor(VerifyPasswordResetByEmailCommand)
final class VerifyPasswordResetByEmailCommandHandler
    implements
        ICommandHandler<
          VerifyPasswordResetByEmailCommand,
          PasswordResetVerifyResultDto
        > {
  VerifyPasswordResetByEmailCommandHandler({
    required IPasswordResetPublicPort publicResetPort,
  }) : _publicResetPort = publicResetPort;

  final IPasswordResetPublicPort _publicResetPort;

  @override
  Future<PasswordResetVerifyResultDto> handle(
    VerifyPasswordResetByEmailCommand command,
  ) {
    return _publicResetPort.verify(
      operationId: command.operationId.trim(),
      code: command.code.trim(),
    );
  }
}
