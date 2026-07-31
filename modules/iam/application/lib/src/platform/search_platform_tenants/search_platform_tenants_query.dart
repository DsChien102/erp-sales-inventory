import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/cursor_page_dto.dart';
import '../../dto/platform_tenant_summary_dto.dart';

/// Search / list Platform Tenants (EP-02/US-08).
@RequiresPermission(IamPlatformPermissions.tenantView)
final class SearchPlatformTenantsQuery
    extends QueryBase<CursorPageDto<PlatformTenantSummaryDto>>
    implements IQuery<CursorPageDto<PlatformTenantSummaryDto>> {
  SearchPlatformTenantsQuery({
    String? id,
    this.query,
    this.status,
    this.readinessState,
    this.warningCode,
    this.cursor,
    this.limit = 20,
  }) : super(id);

  final String? query;
  final TenantLifecycleStatus? status;
  final String? readinessState;
  final String? warningCode;
  final String? cursor;
  final int limit;
}
