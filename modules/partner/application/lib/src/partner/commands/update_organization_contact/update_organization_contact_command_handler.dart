import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_partner_command_gateway.dart';
import 'update_organization_contact_command.dart';

@CommandHandlerFor(UpdateOrganizationContactCommand)
final class UpdateOrganizationContactCommandHandler
    implements ICommandHandler<UpdateOrganizationContactCommand, void> {
  UpdateOrganizationContactCommandHandler({
    required IPartnerCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IPartnerCommandGateway _commandGateway;

  @override
  Future<void> handle(UpdateOrganizationContactCommand command) {
    return _commandGateway.updateOrganizationContact(command);
  }
}
