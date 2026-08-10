import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_tenant_invitation_command_gateway.dart';
import '../../shared/invitation_detail_dto.dart';
import 'create_invitation_command.dart';

@CommandHandlerFor(CreateInvitationCommand)
final class CreateInvitationCommandHandler
    implements
        ICommandHandler<CreateInvitationCommand, InvitationDetailDto> {
  CreateInvitationCommandHandler({
    required ITenantInvitationCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ITenantInvitationCommandGateway _commandGateway;

  @override
  Future<InvitationDetailDto> handle(CreateInvitationCommand command) {
    return _commandGateway.createInvitation(
      tenantId: command.tenantId,
      inviteeEmail: command.inviteeEmail.trim().toLowerCase(),
      initialRoleId: command.initialRoleId.trim(),
      idempotencyKey: command.idempotencyKey.trim(),
    );
  }
}
