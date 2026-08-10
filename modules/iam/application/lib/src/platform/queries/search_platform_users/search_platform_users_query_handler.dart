import 'package:vet45_shared_application/application.dart';

import '../../../shared/cursor_page_dto.dart';
import '../../shared/platform_user_summary_dto.dart';
import '../../../ports/i_platform_admin_gateway.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import 'search_platform_users_query.dart';

@QueryHandlerFor(SearchPlatformUsersQuery)
final class SearchPlatformUsersQueryHandler
    implements
        IQueryHandler<
          SearchPlatformUsersQuery,
          CursorPageDto<PlatformUserSummaryDto>
        > {
  SearchPlatformUsersQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<CursorPageDto<PlatformUserSummaryDto>> handle(
    SearchPlatformUsersQuery query,
  ) {
    if (query.limit < 1 || query.limit > 100) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    return _platformGateway.searchPlatformUsers(
      query: query.query,
      status: query.status,
      cursor: query.cursor,
      limit: query.limit,
    );
  }
}
