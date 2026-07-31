import 'package:vet45_shared_application/application.dart';

import 'activate_tenant_command.dart';

/// Validates activation request shape (§S11).
///
/// Readiness re-evaluation and optimistic concurrency are enforced by the SQL
/// RPC inside the activation transaction; this validator only guards obviously
/// malformed input before hitting infrastructure.
final class ActivateTenantCommandValidator
    implements ICommandValidator<ActivateTenantCommand> {
  @override
  Future<void> validate(ActivateTenantCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('Idempotency key is required');
    }
    if (command.expectedVersion < 0) {
      throw ValidationException('Expected version must be non-negative');
    }
  }
}
