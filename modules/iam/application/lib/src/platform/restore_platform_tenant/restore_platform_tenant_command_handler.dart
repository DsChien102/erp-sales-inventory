import 'package:vet45_shared_application/application.dart';

import '../../ports/i_platform_admin_gateway.dart';
import 'restore_platform_tenant_command.dart';

@CommandHandlerFor(RestorePlatformTenantCommand)
final class RestorePlatformTenantCommandHandler
    implements ICommandHandler<RestorePlatformTenantCommand, void> {
  RestorePlatformTenantCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<void> handle(RestorePlatformTenantCommand command) {
    return _platformGateway.restorePlatformTenant(
      tenantId: command.tenantId,
      expectedVersion: command.expectedVersion,
      idempotencyKey: command.idempotencyKey,
    );
  }
}
