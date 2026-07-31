import 'package:vet45_shared_application/application.dart';

import '../../ports/i_tenant_invitation_read_port.dart';
import '../../shared/iam_blocked_codes.dart';
import '../../shared/iam_blocked_exception.dart';
import '../shared/invitation_detail_dto.dart';
import 'get_invitation_query.dart';

@QueryHandlerFor(GetInvitationQuery)
final class GetInvitationQueryHandler
    implements IQueryHandler<GetInvitationQuery, InvitationDetailDto> {
  GetInvitationQueryHandler({required ITenantInvitationReadPort readPort})
    : _readPort = readPort;

  final ITenantInvitationReadPort _readPort;

  @override
  Future<InvitationDetailDto> handle(GetInvitationQuery query) async {
    final detail = await _readPort.getInvitation(
      tenantId: query.tenantId,
      invitationId: query.invitationId,
    );
    if (detail == null) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return detail;
  }
}
