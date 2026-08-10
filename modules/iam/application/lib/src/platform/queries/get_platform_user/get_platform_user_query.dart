import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/platform_user_detail_dto.dart';

/// Read Platform User detail + memberships (EP-01/US-01).
@RequiresPermission(IamPlatformPermissions.userView)
final class GetPlatformUserQuery extends QueryBase<PlatformUserDetailDto>
    implements IQuery<PlatformUserDetailDto> {
  GetPlatformUserQuery({
    String? id,
    required this.userId,
  }) : super(id);

  final String userId;
}
