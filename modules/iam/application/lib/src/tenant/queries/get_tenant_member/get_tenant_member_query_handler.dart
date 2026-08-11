import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_member_detail_dto.dart';
import '../../../ports/i_tenant_membership_read_gateway.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import 'get_tenant_member_query.dart';

@QueryHandlerFor(GetTenantMemberQuery)
final class GetTenantMemberQueryHandler
    implements IQueryHandler<GetTenantMemberQuery, TenantMemberDetailDto> {
  GetTenantMemberQueryHandler({
    required ITenantMembershipReadGateway readGateway,
  }) : _readGateway = readGateway;

  final ITenantMembershipReadGateway _readGateway;

  @override
  Future<TenantMemberDetailDto> handle(GetTenantMemberQuery query) async {
    final member = await _readGateway.getMember(
      tenantId: query.tenantId,
      membershipId: query.membershipId,
    );
    if (member == null) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return member;
  }
}
