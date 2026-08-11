import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_onboarding_operation_dto.dart';

/// Read durable platform onboarding operation progress (§S15 / OQ-02).
@RequiresPermission(IamPlatformPermissions.tenantCreate)
final class GetTenantOnboardingOperationQuery
    extends QueryBase<TenantOnboardingOperationDto>
    implements IQuery<TenantOnboardingOperationDto> {
  GetTenantOnboardingOperationQuery({
    String? id,
    required this.operationId,
  }) : super(id);

  final String operationId;
}
