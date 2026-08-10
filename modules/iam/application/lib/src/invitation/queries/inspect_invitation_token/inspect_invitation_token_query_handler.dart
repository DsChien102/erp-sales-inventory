import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_tenant_invitation_acceptance_port.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import '../../shared/invitation_token_inspection_dto.dart';
import 'inspect_invitation_token_query.dart';

@QueryHandlerFor(InspectInvitationTokenQuery)
final class InspectInvitationTokenQueryHandler
    implements
        IQueryHandler<InspectInvitationTokenQuery, InvitationTokenInspectionDto> {
  InspectInvitationTokenQueryHandler({
    required ITenantInvitationAcceptancePort acceptancePort,
  }) : _acceptancePort = acceptancePort;

  final ITenantInvitationAcceptancePort _acceptancePort;

  @override
  Future<InvitationTokenInspectionDto> handle(
    InspectInvitationTokenQuery query,
  ) {
    final token = query.token.trim();
    if (token.isEmpty) {
      throw const IamBlockedException(IamBlockedCodes.invitationTokenInvalid);
    }
    return _acceptancePort.inspectToken(token);
  }
}
