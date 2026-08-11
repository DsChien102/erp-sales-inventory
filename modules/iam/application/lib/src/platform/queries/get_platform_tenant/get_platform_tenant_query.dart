import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'platform_tenant_detail_dto.dart';

/// Get Platform Tenant detail (EP-02/US-08).
@RequiresPermission(IamPlatformPermissions.tenantView)
final class GetPlatformTenantQuery extends QueryBase<PlatformTenantDetailDto>
    implements IQuery<PlatformTenantDetailDto> {
  GetPlatformTenantQuery({
    String? id,
    required this.tenantId,
  }) : super(id);

  final String tenantId;
}
