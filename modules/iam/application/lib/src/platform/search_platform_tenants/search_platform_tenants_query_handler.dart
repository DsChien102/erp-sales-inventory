import 'package:vet45_shared_application/application.dart';

import '../../dto/cursor_page_dto.dart';
import '../../dto/platform_tenant_summary_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import '../../shared/iam_blocked_codes.dart';
import '../../shared/iam_blocked_exception.dart';
import 'search_platform_tenants_query.dart';

@QueryHandlerFor(SearchPlatformTenantsQuery)
final class SearchPlatformTenantsQueryHandler
    implements
        IQueryHandler<
          SearchPlatformTenantsQuery,
          CursorPageDto<PlatformTenantSummaryDto>
        > {
  SearchPlatformTenantsQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<CursorPageDto<PlatformTenantSummaryDto>> handle(
    SearchPlatformTenantsQuery query,
  ) {
    if (query.limit < 1 || query.limit > 100) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    return _platformGateway.searchPlatformTenants(
      query: query.query,
      status: query.status,
      readinessState: query.readinessState,
      warningCode: query.warningCode,
      cursor: query.cursor,
      limit: query.limit,
    );
  }
}
