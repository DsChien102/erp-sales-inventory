import 'package:vet45_shared_application/application.dart';

import 'close_platform_tenant_command.dart';

final class ClosePlatformTenantCommandValidator
    implements ICommandValidator<ClosePlatformTenantCommand> {
  @override
  Future<void> validate(ClosePlatformTenantCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required');
    }
    if (command.reason.trim().isEmpty) {
      throw ValidationException('Close reason is required');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('Idempotency key is required');
    }
  }
}
