import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_profile_gateway.dart';
import '../../queries/get_issuance_profile/issuance_profile_dto.dart';
import 'set_default_issuance_configuration_command.dart';

@CommandHandlerFor(SetDefaultIssuanceConfigurationCommand)
final class SetDefaultIssuanceConfigurationCommandHandler
    implements ICommandHandler<SetDefaultIssuanceConfigurationCommand, IssuanceProfileDto> {
  SetDefaultIssuanceConfigurationCommandHandler({
    required IIssuanceProfileGateway profileGateway,
  }) : _profileGateway = profileGateway;

  final IIssuanceProfileGateway _profileGateway;

  @override
  Future<IssuanceProfileDto> handle(
    SetDefaultIssuanceConfigurationCommand command,
  ) {
    return _profileGateway.setDefaultConfiguration(command);
  }
}
