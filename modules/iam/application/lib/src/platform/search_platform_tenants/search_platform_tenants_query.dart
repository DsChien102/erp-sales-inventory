import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_tenant_summary_dto.dart';

/// Search / list Platform Tenants (EP-02/US-08).
@RequiresPermission(IamPlatformPermissions.tenantView)
final class SearchPlatformTenantsQuery
    extends QueryBase<List<PlatformTenantSummaryDto>>
    implements IQuery<List<PlatformTenantSummaryDto>> {
  SearchPlatformTenantsQuery({
    String? id,
    this.query,
    this.status,
  }) : super(id);

  final String? query;
  final TenantLifecycleStatus? status;
}
