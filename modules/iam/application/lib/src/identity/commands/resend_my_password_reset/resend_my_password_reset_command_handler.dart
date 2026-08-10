import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_identity_self_service_port.dart';
import '../../shared/password_reset_request_result_dto.dart';
import 'resend_my_password_reset_command.dart';

@CommandHandlerFor(ResendMyPasswordResetCommand)
final class ResendMyPasswordResetCommandHandler
    implements
        ICommandHandler<ResendMyPasswordResetCommand, PasswordResetRequestResultDto> {
  ResendMyPasswordResetCommandHandler({
    required IPlatformIdentitySelfServicePort identityPort,
  }) : _identityPort = identityPort;

  final IPlatformIdentitySelfServicePort _identityPort;

  @override
  Future<PasswordResetRequestResultDto> handle(
    ResendMyPasswordResetCommand command,
  ) {
    return _identityPort.resendPasswordResetCode(
      operationId: command.operationId.trim(),
    );
  }
}
