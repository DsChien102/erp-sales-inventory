import 'package:vet45_shared_application/application.dart';

import '../../dto/cursor_page_dto.dart';
import '../../dto/tenant_member_dto.dart';
import '../../ports/i_iam_access_gateway.dart';
import '../../shared/iam_blocked_codes.dart';
import '../../shared/iam_blocked_exception.dart';
import 'list_tenant_members_query.dart';

@QueryHandlerFor(ListTenantMembersQuery)
final class ListTenantMembersQueryHandler
    implements
        IQueryHandler<ListTenantMembersQuery, CursorPageDto<TenantMemberDto>> {
  ListTenantMembersQueryHandler({required IIamAccessGateway accessGateway})
    : _accessGateway = accessGateway;

  final IIamAccessGateway _accessGateway;

  @override
  Future<CursorPageDto<TenantMemberDto>> handle(
    ListTenantMembersQuery query,
  ) async {
    final limit = query.limit;
    if (limit < 1 || limit > 100) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    final search = query.search?.trim();
    final status = query.status?.trim();
    if (status != null &&
        status.isNotEmpty &&
        status != 'active' &&
        status != 'inactive' &&
        status != 'removed') {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }

    return _accessGateway.listTenantMembers(
      tenantId: query.tenantId,
      search: (search == null || search.isEmpty) ? null : search,
      status: (status == null || status.isEmpty) ? null : status,
      cursor: query.cursor,
      limit: limit,
    );
  }
}
