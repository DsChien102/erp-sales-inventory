import 'package:vet45_shared_application/application.dart';

import '../../ports/i_platform_admin_gateway.dart';
import 'suspend_platform_tenant_command.dart';

@CommandHandlerFor(SuspendPlatformTenantCommand)
final class SuspendPlatformTenantCommandHandler
    implements ICommandHandler<SuspendPlatformTenantCommand, void> {
  SuspendPlatformTenantCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<void> handle(SuspendPlatformTenantCommand command) {
    return _platformGateway.suspendPlatformTenant(
      tenantId: command.tenantId,
      reason: command.reason,
      expectedVersion: command.expectedVersion,
      idempotencyKey: command.idempotencyKey,
    );
  }
}
