import 'package:vet45_shared_application/application.dart';

import 'transfer_platform_tenant_ownership_command.dart';

final class TransferPlatformTenantOwnershipCommandValidator
    implements ICommandValidator<TransferPlatformTenantOwnershipCommand> {
  @override
  Future<void> validate(TransferPlatformTenantOwnershipCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required');
    }
    if (command.newOwnerUserId.trim().isEmpty) {
      throw ValidationException('New owner user id is required');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('Idempotency key is required');
    }
  }
}
