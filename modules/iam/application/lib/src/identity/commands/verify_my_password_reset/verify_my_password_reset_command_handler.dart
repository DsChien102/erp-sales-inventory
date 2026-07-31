import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_identity_self_service_port.dart';
import '../../../dto/password_reset_verify_result_dto.dart';
import 'verify_my_password_reset_command.dart';

@CommandHandlerFor(VerifyMyPasswordResetCommand)
final class VerifyMyPasswordResetCommandHandler
    implements ICommandHandler<VerifyMyPasswordResetCommand, PasswordResetVerifyResultDto> {
  VerifyMyPasswordResetCommandHandler({
    required IPlatformIdentitySelfServicePort identityPort,
  }) : _identityPort = identityPort;

  final IPlatformIdentitySelfServicePort _identityPort;

  @override
  Future<PasswordResetVerifyResultDto> handle(VerifyMyPasswordResetCommand command) {
    return _identityPort.verifyPasswordResetCode(
      operationId: command.operationId.trim(),
      code: command.code.trim(),
    );
  }
}
