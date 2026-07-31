import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_member_detail_dto.dart';

@RequiresPermission(IamPermissions.memberView)
@RequiresTenant()
final class GetTenantMemberQuery extends QueryBase<TenantMemberDetailDto>
    implements IQuery<TenantMemberDetailDto>, ITenantScopedCommand {
  GetTenantMemberQuery({
    String? id,
    required this.tenantId,
    required this.membershipId,
  }) : super(id);

  @override
  final String tenantId;
  final String membershipId;
}
