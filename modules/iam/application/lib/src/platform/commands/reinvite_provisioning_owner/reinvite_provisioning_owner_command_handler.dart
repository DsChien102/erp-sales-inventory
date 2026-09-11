import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_admin_gateway.dart';
import '../../shared/tenant_onboarding_result_dto.dart';
import 'reinvite_provisioning_owner_command.dart';

@CommandHandlerFor(ReinviteProvisioningOwnerCommand)
final class ReinviteProvisioningOwnerCommandHandler
    implements
        ICommandHandler<
          ReinviteProvisioningOwnerCommand,
          TenantOnboardingResultDto
        > {
  ReinviteProvisioningOwnerCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<TenantOnboardingResultDto> handle(
    ReinviteProvisioningOwnerCommand command,
  ) async {
    final owner = command.owner;
    if (owner.isNewUser) {
      return _platformGateway.reinviteProvisioningOwner(
        tenantId: command.tenantId,
        isNewUser: true,
        idempotencyKey: command.idempotencyKey,
        correlationId: command.correlationId,
        ownerEmail: owner.email,
        ownerGivenName: owner.firstName,
        ownerFamilyName: owner.lastName,
        ownerPhone: owner.phone,
      );
    }
    return _platformGateway.reinviteProvisioningOwner(
      tenantId: command.tenantId,
      isNewUser: false,
      idempotencyKey: command.idempotencyKey,
      correlationId: command.correlationId,
      ownerUserId: owner.existingUserId,
    );
  }
}
