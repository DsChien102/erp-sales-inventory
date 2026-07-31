import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_onboarding_operation_dto.dart';

/// Resume a partial/failed onboarding operation from incomplete steps (§S15).
@RequiresPermission(IamPlatformPermissions.tenantCreate)
@Idempotent(keyField: 'idempotencyKey')
final class RetryTenantOnboardingOperationCommand
    extends CommandBase<TenantOnboardingOperationDto>
    implements ICommand<TenantOnboardingOperationDto> {
  RetryTenantOnboardingOperationCommand({
    String? id,
    required this.operationId,
    required this.idempotencyKey,
  }) : super(id);

  final String operationId;
  final String idempotencyKey;
}
