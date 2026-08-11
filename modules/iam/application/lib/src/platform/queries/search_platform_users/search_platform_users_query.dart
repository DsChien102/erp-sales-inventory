import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/cursor_page_dto.dart';
import '../../shared/platform_user_status.dart';
import '../../shared/platform_user_summary_dto.dart';

/// Search / list Platform Users (EP-01/US-01).
@RequiresPermission(IamPlatformPermissions.userView)
final class SearchPlatformUsersQuery
    extends QueryBase<CursorPageDto<PlatformUserSummaryDto>>
    implements IQuery<CursorPageDto<PlatformUserSummaryDto>> {
  SearchPlatformUsersQuery({
    String? id,
    this.query,
    this.status,
    this.cursor,
    this.limit = 20,
  }) : super(id);

  final String? query;
  final PlatformUserStatus? status;
  final String? cursor;
  final int limit;
}
