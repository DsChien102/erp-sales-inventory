import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_member_dto.dart';

@RequiresPermission(IamPermissions.membersRead)
@RequiresTenant()
final class ListTenantMembersQuery extends QueryBase<List<TenantMemberDto>>
    implements IQuery<List<TenantMemberDto>>, ITenantScopedCommand {
  ListTenantMembersQuery({
    String? id,
    required this.tenantId,
  }) : super(id);

  @override
  final String tenantId;
}
