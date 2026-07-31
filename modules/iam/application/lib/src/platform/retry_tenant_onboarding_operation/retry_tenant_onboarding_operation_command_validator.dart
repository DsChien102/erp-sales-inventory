import 'package:vet45_shared_application/application.dart';

import 'retry_tenant_onboarding_operation_command.dart';

final class RetryTenantOnboardingOperationCommandValidator
    implements ICommandValidator<RetryTenantOnboardingOperationCommand> {
  @override
  Future<void> validate(RetryTenantOnboardingOperationCommand command) async {
    if (command.operationId.trim().isEmpty) {
      throw ValidationException('Operation id is required');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('Idempotency key is required');
    }
  }
}
