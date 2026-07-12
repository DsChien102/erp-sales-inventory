import 'package:vet45_shared_application/application.dart';

import 'configure_custom_field_attributes_command.dart';

final class ConfigureCustomFieldAttributesCommandValidator
    implements ICommandValidator<ConfigureCustomFieldAttributesCommand> {
  @override
  Future<void> validate(ConfigureCustomFieldAttributesCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.fieldId.trim().isEmpty) {
      throw ValidationException('Field id is required.');
    }
  }
}
