import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_tenant_member_dto.dart';

/// List Platform Tenant members (EP-02/US-08).
@RequiresPermission(IamPlatformPermissions.tenantMemberView)
final class ListPlatformTenantMembersQuery
    extends QueryBase<List<PlatformTenantMemberDto>>
    implements IQuery<List<PlatformTenantMemberDto>> {
  ListPlatformTenantMembersQuery({
    String? id,
    required this.tenantId,
  }) : super(id);

  final String tenantId;
}
