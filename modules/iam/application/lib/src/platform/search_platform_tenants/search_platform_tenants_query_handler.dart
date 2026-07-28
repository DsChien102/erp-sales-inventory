import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_tenant_summary_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import 'search_platform_tenants_query.dart';

@QueryHandlerFor(SearchPlatformTenantsQuery)
final class SearchPlatformTenantsQueryHandler
    implements
        IQueryHandler<SearchPlatformTenantsQuery, List<PlatformTenantSummaryDto>> {
  SearchPlatformTenantsQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<List<PlatformTenantSummaryDto>> handle(
    SearchPlatformTenantsQuery query,
  ) {
    return _platformGateway.searchPlatformTenants(
      query: query.query,
      status: query.status,
    );
  }
}
