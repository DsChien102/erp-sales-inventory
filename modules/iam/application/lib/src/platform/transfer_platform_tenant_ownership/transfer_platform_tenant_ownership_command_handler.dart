import 'package:vet45_shared_application/application.dart';

import '../../ports/i_platform_admin_gateway.dart';
import 'transfer_platform_tenant_ownership_command.dart';

@CommandHandlerFor(TransferPlatformTenantOwnershipCommand)
final class TransferPlatformTenantOwnershipCommandHandler
    implements ICommandHandler<TransferPlatformTenantOwnershipCommand, void> {
  TransferPlatformTenantOwnershipCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<void> handle(TransferPlatformTenantOwnershipCommand command) {
    return _platformGateway.transferPlatformTenantOwnership(
      tenantId: command.tenantId,
      newOwnerUserId: command.newOwnerUserId,
      idempotencyKey: command.idempotencyKey,
    );
  }
}
