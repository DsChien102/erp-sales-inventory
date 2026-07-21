import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/onboarding_owner_input.dart';
import '../../dto/tenant_onboarding_result_dto.dart';

/// Atomic tenant + first-owner onboarding (EP-01/US-03).
///
/// Creates Tenant (provisioning), Owner Membership (`is_owner=true`,
/// role Chủ cửa hàng), and optionally a pending Platform User.
/// Retry-safe via [idempotencyKey] (BR-05).
@RequiresPermission(IamPlatformPermissions.tenantCreate)
@Idempotent(keyField: 'idempotencyKey')
final class CreateTenantOnboardingCommand
    extends CommandBase<TenantOnboardingResultDto>
    implements ICommand<TenantOnboardingResultDto> {
  CreateTenantOnboardingCommand({
    String? id,
    required this.owner,
    required this.organizationName,
    required this.idempotencyKey,
    this.correlationId,
  }) : super(id);

  final OnboardingOwnerInput owner;
  final String organizationName;
  final String idempotencyKey;
  final String? correlationId;
}
