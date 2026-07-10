import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_partner_command_gateway.dart';
import 'remove_organization_contact_command.dart';

@CommandHandlerFor(RemoveOrganizationContactCommand)
final class RemoveOrganizationContactCommandHandler
    implements ICommandHandler<RemoveOrganizationContactCommand, void> {
  RemoveOrganizationContactCommandHandler({
    required IPartnerCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IPartnerCommandGateway _commandGateway;

  @override
  Future<void> handle(RemoveOrganizationContactCommand command) {
    return _commandGateway.removeOrganizationContact(command);
  }
}
