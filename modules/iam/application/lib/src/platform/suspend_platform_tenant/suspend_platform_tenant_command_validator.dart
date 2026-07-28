import 'package:vet45_shared_application/application.dart';

import 'suspend_platform_tenant_command.dart';

final class SuspendPlatformTenantCommandValidator
    implements ICommandValidator<SuspendPlatformTenantCommand> {
  @override
  Future<void> validate(SuspendPlatformTenantCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required');
    }
    if (command.reason.trim().isEmpty) {
      throw ValidationException('Suspend reason is required');
    }
  }
}
