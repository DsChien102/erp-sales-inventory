import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_member_detail_dto.dart';
import '../../ports/i_tenant_invitation_acceptance_port.dart';
import '../../shared/iam_blocked_codes.dart';
import '../../shared/iam_blocked_exception.dart';
import 'accept_invitation_command.dart';

@CommandHandlerFor(AcceptInvitationCommand)
final class AcceptInvitationCommandHandler
    implements ICommandHandler<AcceptInvitationCommand, TenantMemberDetailDto> {
  AcceptInvitationCommandHandler({
    required ITenantInvitationAcceptancePort acceptancePort,
  }) : _acceptancePort = acceptancePort;

  final ITenantInvitationAcceptancePort _acceptancePort;

  @override
  Future<TenantMemberDetailDto> handle(AcceptInvitationCommand command) {
    final token = command.token.trim();
    final key = command.idempotencyKey.trim();
    if (token.isEmpty) {
      throw const IamBlockedException(IamBlockedCodes.invitationTokenInvalid);
    }
    if (key.isEmpty) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    return _acceptancePort.acceptInvitation(token: token, idempotencyKey: key);
  }
}
