import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/onboarding_owner_input.dart';
import '../../shared/tenant_onboarding_result_dto.dart';

/// Thay Owner Invitation trên Tenant provisioning (token cũ hết hiệu lực).
/// Không tạo profile/Membership trước khi accept.
@RequiresPermission(IamPlatformPermissions.tenantCreate)
@Idempotent(keyField: 'idempotencyKey')
final class ReinviteProvisioningOwnerCommand extends CommandBase<TenantOnboardingResultDto>
    implements ICommand<TenantOnboardingResultDto> {
  ReinviteProvisioningOwnerCommand({
    String? id,
    required this.tenantId,
    required this.owner,
    required this.idempotencyKey,
    this.correlationId,
  }) : super(id);

  final String tenantId;
  final OnboardingOwnerInput owner;
  final String idempotencyKey;
  final String? correlationId;
}
