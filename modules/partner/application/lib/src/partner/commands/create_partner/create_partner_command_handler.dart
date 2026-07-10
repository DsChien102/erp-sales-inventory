import 'package:vet45_shared_application/application.dart';

import '../../../services/partner_domain_mapper.dart';
import '../../../ports/i_partner_command_gateway.dart';
import 'create_partner_command.dart';
import 'create_partner_result.dart';

@CommandHandlerFor(CreatePartnerCommand)
final class CreatePartnerCommandHandler
    implements ICommandHandler<CreatePartnerCommand, CreatePartnerResult> {
  CreatePartnerCommandHandler({required IPartnerCommandGateway commandGateway})
    : _commandGateway = commandGateway;

  final IPartnerCommandGateway _commandGateway;

  @override
  Future<CreatePartnerResult> handle(CreatePartnerCommand command) async {
    PartnerDomainMapper.validateCreate(command);
    return _commandGateway.createPartner(command);
  }
}
