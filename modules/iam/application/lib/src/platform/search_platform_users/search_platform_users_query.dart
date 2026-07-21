import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_user_status.dart';
import '../../dto/platform_user_summary_dto.dart';

/// Search / list Platform Users (EP-01/US-01).
@RequiresPermission(IamPlatformPermissions.userView)
final class SearchPlatformUsersQuery
    extends QueryBase<List<PlatformUserSummaryDto>>
    implements IQuery<List<PlatformUserSummaryDto>> {
  SearchPlatformUsersQuery({
    String? id,
    this.query,
    this.status,
  }) : super(id);

  /// Free-text search by name or email (optional).
  final String? query;

  /// Filter by identity status (optional).
  final PlatformUserStatus? status;
}
