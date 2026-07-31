import 'package:vet45_shared_application/application.dart';

import '../../ports/i_tenant_invitation_command_gateway.dart';
import '../shared/invitation_detail_dto.dart';
import 'revoke_invitation_command.dart';

@CommandHandlerFor(RevokeInvitationCommand)
final class RevokeInvitationCommandHandler
    implements ICommandHandler<RevokeInvitationCommand, InvitationDetailDto> {
  RevokeInvitationCommandHandler({
    required ITenantInvitationCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ITenantInvitationCommandGateway _commandGateway;

  @override
  Future<InvitationDetailDto> handle(RevokeInvitationCommand command) {
    return _commandGateway.revokeInvitation(
      tenantId: command.tenantId,
      invitationId: command.invitationId.trim(),
      expectedVersion: command.expectedVersion,
      reason: command.reason.trim(),
      idempotencyKey: command.idempotencyKey.trim(),
    );
  }
}
