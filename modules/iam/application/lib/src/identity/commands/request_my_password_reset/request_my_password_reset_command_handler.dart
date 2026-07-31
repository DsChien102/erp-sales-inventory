import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_identity_self_service_port.dart';
import '../../../dto/password_reset_request_result_dto.dart';
import 'request_my_password_reset_command.dart';

@CommandHandlerFor(RequestMyPasswordResetCommand)
final class RequestMyPasswordResetCommandHandler
    implements
        ICommandHandler<RequestMyPasswordResetCommand, PasswordResetRequestResultDto> {
  RequestMyPasswordResetCommandHandler({
    required IPlatformIdentitySelfServicePort identityPort,
  }) : _identityPort = identityPort;

  final IPlatformIdentitySelfServicePort _identityPort;

  @override
  Future<PasswordResetRequestResultDto> handle(
    RequestMyPasswordResetCommand command,
  ) {
    return _identityPort.requestPasswordReset();
  }
}
