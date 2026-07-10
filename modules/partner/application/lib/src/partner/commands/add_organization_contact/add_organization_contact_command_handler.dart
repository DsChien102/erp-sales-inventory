import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_partner_command_gateway.dart';
import 'add_organization_contact_command.dart';
import 'add_organization_contact_result.dart';

@CommandHandlerFor(AddOrganizationContactCommand)
final class AddOrganizationContactCommandHandler
    implements
        ICommandHandler<
          AddOrganizationContactCommand,
          AddOrganizationContactResult
        > {
  AddOrganizationContactCommandHandler({
    required IPartnerCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IPartnerCommandGateway _commandGateway;

  @override
  Future<AddOrganizationContactResult> handle(
    AddOrganizationContactCommand command,
  ) {
    return _commandGateway.addOrganizationContact(command);
  }
}
