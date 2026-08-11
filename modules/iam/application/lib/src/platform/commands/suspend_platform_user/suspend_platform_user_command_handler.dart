import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_admin_gateway.dart';
import 'suspend_platform_user_command.dart';

@CommandHandlerFor(SuspendPlatformUserCommand)
final class SuspendPlatformUserCommandHandler
    implements ICommandHandler<SuspendPlatformUserCommand, void> {
  SuspendPlatformUserCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<void> handle(SuspendPlatformUserCommand command) {
    return _platformGateway.suspendPlatformUser(
      userId: command.userId,
      reason: command.reason,
      expectedVersion: command.expectedVersion,
      idempotencyKey: command.idempotencyKey,
    );
  }
}
