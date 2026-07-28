import 'package:vet45_shared_application/application.dart';

import 'restore_platform_tenant_command.dart';

final class RestorePlatformTenantCommandValidator
    implements ICommandValidator<RestorePlatformTenantCommand> {
  @override
  Future<void> validate(RestorePlatformTenantCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required');
    }
  }
}
