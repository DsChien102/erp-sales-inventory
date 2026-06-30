import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_member_dto.dart';
import '../../ports/i_iam_access_gateway.dart';
import 'list_tenant_members_query.dart';

@QueryHandlerFor(ListTenantMembersQuery)
final class ListTenantMembersQueryHandler
    implements IQueryHandler<ListTenantMembersQuery, List<TenantMemberDto>> {
  ListTenantMembersQueryHandler({required IIamAccessGateway accessGateway})
    : _accessGateway = accessGateway;

  final IIamAccessGateway _accessGateway;

  @override
  Future<List<TenantMemberDto>> handle(ListTenantMembersQuery query) {
    return _accessGateway.listTenantMembers(query.tenantId);
  }
}
