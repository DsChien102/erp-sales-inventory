import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_admin_gateway.dart';
import 'close_platform_tenant_command.dart';

@CommandHandlerFor(ClosePlatformTenantCommand)
final class ClosePlatformTenantCommandHandler
    implements ICommandHandler<ClosePlatformTenantCommand, void> {
  ClosePlatformTenantCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<void> handle(ClosePlatformTenantCommand command) {
    return _platformGateway.closePlatformTenant(
      tenantId: command.tenantId,
      reason: command.reason,
      expectedVersion: command.expectedVersion,
      idempotencyKey: command.idempotencyKey,
    );
  }
}
