import 'package:vet45_shared_application/application.dart';

import '../../ports/i_platform_admin_gateway.dart';
import 'request_platform_password_reset_command.dart';

@CommandHandlerFor(RequestPlatformPasswordResetCommand)
final class RequestPlatformPasswordResetCommandHandler
    implements ICommandHandler<RequestPlatformPasswordResetCommand, void> {
  RequestPlatformPasswordResetCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<void> handle(RequestPlatformPasswordResetCommand command) {
    return _platformGateway.requestPasswordReset(command.userId);
  }
}
