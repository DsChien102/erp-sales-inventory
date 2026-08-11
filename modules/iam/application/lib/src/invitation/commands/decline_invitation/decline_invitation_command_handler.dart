import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_tenant_invitation_acceptance_port.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import '../../shared/invitation_detail_dto.dart';
import 'decline_invitation_command.dart';

@CommandHandlerFor(DeclineInvitationCommand)
final class DeclineInvitationCommandHandler
    implements ICommandHandler<DeclineInvitationCommand, InvitationDetailDto> {
  DeclineInvitationCommandHandler({
    required ITenantInvitationAcceptancePort acceptancePort,
  }) : _acceptancePort = acceptancePort;

  final ITenantInvitationAcceptancePort _acceptancePort;

  @override
  Future<InvitationDetailDto> handle(DeclineInvitationCommand command) {
    final token = command.token.trim();
    final key = command.idempotencyKey.trim();
    if (token.isEmpty) {
      throw const IamBlockedException(IamBlockedCodes.invitationTokenInvalid);
    }
    if (key.isEmpty) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    return _acceptancePort.declineInvitation(token: token, idempotencyKey: key);
  }
}
