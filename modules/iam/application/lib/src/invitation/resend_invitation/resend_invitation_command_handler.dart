import 'package:vet45_shared_application/application.dart';

import '../../ports/i_tenant_invitation_command_gateway.dart';
import '../shared/invitation_detail_dto.dart';
import 'resend_invitation_command.dart';

@CommandHandlerFor(ResendInvitationCommand)
final class ResendInvitationCommandHandler
    implements ICommandHandler<ResendInvitationCommand, InvitationDetailDto> {
  ResendInvitationCommandHandler({
    required ITenantInvitationCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ITenantInvitationCommandGateway _commandGateway;

  @override
  Future<InvitationDetailDto> handle(ResendInvitationCommand command) {
    return _commandGateway.resendInvitation(
      tenantId: command.tenantId,
      invitationId: command.invitationId.trim(),
      expectedVersion: command.expectedVersion,
      idempotencyKey: command.idempotencyKey.trim(),
    );
  }
}
