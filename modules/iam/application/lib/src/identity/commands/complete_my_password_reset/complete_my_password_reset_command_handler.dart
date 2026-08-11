import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_identity_self_service_port.dart';
import '../../shared/password_reset_completion_result_dto.dart';
import 'complete_my_password_reset_command.dart';

@CommandHandlerFor(CompleteMyPasswordResetCommand)
final class CompleteMyPasswordResetCommandHandler
    implements ICommandHandler<CompleteMyPasswordResetCommand, PasswordResetCompletionResultDto> {
  CompleteMyPasswordResetCommandHandler({
    required IPlatformIdentitySelfServicePort identityPort,
  }) : _identityPort = identityPort;

  final IPlatformIdentitySelfServicePort _identityPort;

  @override
  Future<PasswordResetCompletionResultDto> handle(
    CompleteMyPasswordResetCommand command,
  ) {
    return _identityPort.completePasswordReset(
      operationId: command.operationId.trim(),
      newPassword: command.newPassword,
    );
  }
}
