import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_admin_gateway.dart';
import 'restore_platform_user_command.dart';

@CommandHandlerFor(RestorePlatformUserCommand)
final class RestorePlatformUserCommandHandler
    implements ICommandHandler<RestorePlatformUserCommand, void> {
  RestorePlatformUserCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<void> handle(RestorePlatformUserCommand command) {
    return _platformGateway.restorePlatformUser(
      userId: command.userId,
      expectedVersion: command.expectedVersion,
      idempotencyKey: command.idempotencyKey,
    );
  }
}
