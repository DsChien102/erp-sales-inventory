import 'package:vet45_shared_application/application.dart';

import 'set_default_issuance_configuration_command.dart';

final class SetDefaultIssuanceConfigurationCommandValidator
    implements ICommandValidator<SetDefaultIssuanceConfigurationCommand> {
  @override
  Future<void> validate(SetDefaultIssuanceConfigurationCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.templateId.trim().isEmpty) {
      throw ValidationException('templateId is required');
    }
    if (command.signingConfigId.trim().isEmpty) {
      throw ValidationException('signingConfigId is required');
    }
  }
}
