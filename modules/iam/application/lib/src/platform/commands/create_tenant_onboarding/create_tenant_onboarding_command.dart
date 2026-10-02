import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/onboarding_owner_input.dart';
import '../../shared/tenant_onboarding_result_dto.dart';

/// Hybrid: creates Tenant (provisioning), Owner Membership immediately, and
/// an owner activation invitation. Retry-safe via [idempotencyKey] (BR-05).
@RequiresPermission(IamPlatformPermissions.tenantCreate)
@Idempotent(keyField: 'idempotencyKey')
final class CreateTenantOnboardingCommand extends CommandBase<TenantOnboardingResultDto>
    implements ICommand<TenantOnboardingResultDto> {
  CreateTenantOnboardingCommand({
    String? id,
    required this.owner,
    required this.organizationName,
    required this.idempotencyKey,
    this.organizationDisplayName,
    this.contactEmail,
    this.contactPhone,
    this.contactAddressText,
    this.provinceCode,
    this.communeCode,
    this.legalName,
    this.taxCode,
    this.legalEntityType,
    this.registeredAddressText,
    this.correlationId,
  }) : super(id);

  final OnboardingOwnerInput owner;
  final String organizationName;
  final String idempotencyKey;
  final String? organizationDisplayName;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactAddressText;
  final String? provinceCode;
  final String? communeCode;
  final String? legalName;
  final String? taxCode;

  /// `HOUSEHOLD_BUSINESS` | `ENTERPRISE`; required when legal name + tax code given.
  final String? legalEntityType;
  final String? registeredAddressText;
  final String? correlationId;
}
