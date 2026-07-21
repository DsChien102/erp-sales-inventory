import 'package:vet45_shared_application/application.dart';

import 'switch_tenant_context_command.dart';

/// Pipeline validator for [SwitchTenantContextCommand].
///
/// Non-empty target only. Same-tenant check (BR-02) runs in the handler with
/// [ICurrentTenant] (codegen validators use zero-arg / simple factories).
final class SwitchTenantContextCommandValidator
    implements ICommandValidator<SwitchTenantContextCommand> {
  @override
  Future<void> validate(SwitchTenantContextCommand command) async {
    if (command.targetTenantId.trim().isEmpty) {
      throw ValidationException('targetTenantId is required');
    }
  }
}
