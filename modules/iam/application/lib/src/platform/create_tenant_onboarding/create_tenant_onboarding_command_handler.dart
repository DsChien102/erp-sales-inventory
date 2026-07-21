import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_onboarding_result_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import 'create_tenant_onboarding_command.dart';

@CommandHandlerFor(CreateTenantOnboardingCommand)
final class CreateTenantOnboardingCommandHandler
    implements
        ICommandHandler<CreateTenantOnboardingCommand, TenantOnboardingResultDto> {
  CreateTenantOnboardingCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<TenantOnboardingResultDto> handle(
    CreateTenantOnboardingCommand command,
  ) {
    return _platformGateway.createTenantOnboarding(
      owner: command.owner,
      organizationName: command.organizationName,
      idempotencyKey: command.idempotencyKey,
      correlationId: command.correlationId,
    );
  }
}
