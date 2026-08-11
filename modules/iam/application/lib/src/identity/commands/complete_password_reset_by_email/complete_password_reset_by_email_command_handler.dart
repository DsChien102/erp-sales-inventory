import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_password_reset_public_port.dart';
import '../../shared/password_reset_completion_result_dto.dart';
import 'complete_password_reset_by_email_command.dart';

@CommandHandlerFor(CompletePasswordResetByEmailCommand)
final class CompletePasswordResetByEmailCommandHandler
    implements
        ICommandHandler<
          CompletePasswordResetByEmailCommand,
          PasswordResetCompletionResultDto
        > {
  CompletePasswordResetByEmailCommandHandler({
    required IPasswordResetPublicPort publicResetPort,
  }) : _publicResetPort = publicResetPort;

  final IPasswordResetPublicPort _publicResetPort;

  @override
  Future<PasswordResetCompletionResultDto> handle(
    CompletePasswordResetByEmailCommand command,
  ) {
    return _publicResetPort.complete(
      operationId: command.operationId.trim(),
      newPassword: command.newPassword,
    );
  }
}
