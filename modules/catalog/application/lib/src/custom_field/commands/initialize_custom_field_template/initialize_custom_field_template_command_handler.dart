import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_custom_field_config_gateway.dart';
import 'initialize_custom_field_template_command.dart';
import 'initialize_custom_field_template_command_validator.dart';
import 'initialize_custom_field_template_result.dart';

@CommandHandlerFor(InitializeCustomFieldTemplateCommand)
final class InitializeCustomFieldTemplateCommandHandler
    implements
        ICommandHandler<InitializeCustomFieldTemplateCommand, InitializeCustomFieldTemplateResult> {
  InitializeCustomFieldTemplateCommandHandler({
    required ICatalogCustomFieldConfigGateway customFieldConfigGateway,
    InitializeCustomFieldTemplateCommandValidator? validator,
  }) : _customFieldConfigGateway = customFieldConfigGateway,
       _validator = validator ?? InitializeCustomFieldTemplateCommandValidator();

  final ICatalogCustomFieldConfigGateway _customFieldConfigGateway;
  final InitializeCustomFieldTemplateCommandValidator _validator;

  @override
  Future<InitializeCustomFieldTemplateResult> handle(
    InitializeCustomFieldTemplateCommand command,
  ) async {
    await _validator.validate(command);
    return _customFieldConfigGateway.initializeTemplate(command: command);
  }
}
