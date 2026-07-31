import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_onboarding_operation_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import 'retry_tenant_onboarding_operation_command.dart';

@CommandHandlerFor(RetryTenantOnboardingOperationCommand)
final class RetryTenantOnboardingOperationCommandHandler
    implements
        ICommandHandler<
          RetryTenantOnboardingOperationCommand,
          TenantOnboardingOperationDto
        > {
  RetryTenantOnboardingOperationCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<TenantOnboardingOperationDto> handle(
    RetryTenantOnboardingOperationCommand command,
  ) {
    return _platformGateway.retryTenantOnboardingOperation(
      operationId: command.operationId,
      idempotencyKey: command.idempotencyKey,
    );
  }
}
