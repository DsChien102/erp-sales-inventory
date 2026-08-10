import 'package:vet45_shared_application/application.dart';

import '../../../shared/cursor_page_dto.dart';
import '../../../ports/i_tenant_invitation_read_port.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import '../../shared/invitation_summary_dto.dart';
import 'list_invitations_query.dart';

@QueryHandlerFor(ListInvitationsQuery)
final class ListInvitationsQueryHandler
    implements
        IQueryHandler<ListInvitationsQuery, CursorPageDto<InvitationSummaryDto>> {
  ListInvitationsQueryHandler({required ITenantInvitationReadPort readPort})
    : _readPort = readPort;

  final ITenantInvitationReadPort _readPort;

  static const _allowedStatus = <String>{
    'pending',
    'accepted',
    'declined',
    'revoked',
    'expired',
  };

  @override
  Future<CursorPageDto<InvitationSummaryDto>> handle(
    ListInvitationsQuery query,
  ) async {
    final limit = query.limit;
    if (limit < 1 || limit > 100) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    final search = query.search?.trim();
    final status = query.status?.trim();
    if (status != null &&
        status.isNotEmpty &&
        !_allowedStatus.contains(status)) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }

    return _readPort.listInvitations(
      tenantId: query.tenantId,
      search: (search == null || search.isEmpty) ? null : search,
      status: (status == null || status.isEmpty) ? null : status,
      cursor: query.cursor,
      limit: limit,
    );
  }
}
