import 'package:vet45_shared_application/application.dart';

import '../../shared/platform_tenant_member_dto.dart';
import '../../../ports/i_platform_admin_gateway.dart';
import 'list_platform_tenant_members_query.dart';

@QueryHandlerFor(ListPlatformTenantMembersQuery)
final class ListPlatformTenantMembersQueryHandler
    implements
        IQueryHandler<
          ListPlatformTenantMembersQuery,
          List<PlatformTenantMemberDto>
        > {
  ListPlatformTenantMembersQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<List<PlatformTenantMemberDto>> handle(
    ListPlatformTenantMembersQuery query,
  ) {
    return _platformGateway.listPlatformTenantMembers(query.tenantId);
  }
}
