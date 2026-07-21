import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_user_summary_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import 'search_platform_users_query.dart';

@QueryHandlerFor(SearchPlatformUsersQuery)
final class SearchPlatformUsersQueryHandler
    implements
        IQueryHandler<SearchPlatformUsersQuery, List<PlatformUserSummaryDto>> {
  SearchPlatformUsersQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<List<PlatformUserSummaryDto>> handle(
    SearchPlatformUsersQuery query,
  ) {
    return _platformGateway.searchPlatformUsers(
      query: query.query,
      status: query.status,
    );
  }
}
