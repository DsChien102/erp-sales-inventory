import 'package:vet45_shared_application/application.dart';

import 'initialize_custom_field_template_command.dart';

final class InitializeCustomFieldTemplateCommandValidator
    implements ICommandValidator<InitializeCustomFieldTemplateCommand> {
  @override
  Future<void> validate(InitializeCustomFieldTemplateCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
  }
}
