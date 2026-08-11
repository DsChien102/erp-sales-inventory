import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_onboarding_result_dto.dart';
import '../../../ports/i_platform_admin_gateway.dart';
import 'create_tenant_onboarding_command.dart';

/// Hướng 1: for a NEW owner the account is NOT created here — onboarding issues an
/// activation code (the owner signs up + accepts later). For an existing owner the
/// membership is created immediately. No identity pre-provisioning either way.
@CommandHandlerFor(CreateTenantOnboardingCommand)
final class CreateTenantOnboardingCommandHandler
    implements ICommandHandler<CreateTenantOnboardingCommand, TenantOnboardingResultDto> {
  CreateTenantOnboardingCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<TenantOnboardingResultDto> handle(
    CreateTenantOnboardingCommand command,
  ) async {
    final owner = command.owner;
    if (owner.isNewUser) {
      return _platformGateway.createTenantOnboarding(
        isNewUser: true,
        organizationName: command.organizationName,
        idempotencyKey: command.idempotencyKey,
        correlationId: command.correlationId,
        organizationDisplayName: command.organizationDisplayName,
        contactEmail: command.contactEmail,
        contactPhone: command.contactPhone,
        contactAddressText: command.contactAddressText,
        provinceCode: command.provinceCode,
        communeCode: command.communeCode,
        legalName: command.legalName,
        taxCode: command.taxCode,
        ownerEmail: owner.email,
        ownerGivenName: owner.firstName,
        ownerFamilyName: owner.lastName,
        ownerPhone: owner.phone,
      );
    }
    return _platformGateway.createTenantOnboarding(
      isNewUser: false,
      organizationName: command.organizationName,
      idempotencyKey: command.idempotencyKey,
      correlationId: command.correlationId,
      organizationDisplayName: command.organizationDisplayName,
      contactEmail: command.contactEmail,
      contactPhone: command.contactPhone,
      contactAddressText: command.contactAddressText,
      provinceCode: command.provinceCode,
      communeCode: command.communeCode,
      legalName: command.legalName,
      taxCode: command.taxCode,
      ownerUserId: owner.existingUserId,
    );
  }
}
