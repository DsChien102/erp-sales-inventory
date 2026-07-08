import 'package:vet45_shared_application/application.dart';

import '../../ports/i_catalog_custom_field_config_gateway.dart';
import 'configure_custom_field_attributes_command.dart';
import 'configure_custom_field_attributes_command_validator.dart';
import 'configure_custom_field_attributes_result.dart';

@CommandHandlerFor(ConfigureCustomFieldAttributesCommand)
final class ConfigureCustomFieldAttributesCommandHandler
    implements
        ICommandHandler<
          ConfigureCustomFieldAttributesCommand,
          ConfigureCustomFieldAttributesResult
        > {
  ConfigureCustomFieldAttributesCommandHandler({
    required ICatalogCustomFieldConfigGateway customFieldConfigGateway,
    ConfigureCustomFieldAttributesCommandValidator? validator,
  }) : _customFieldConfigGateway = customFieldConfigGateway,
       _validator = validator ?? ConfigureCustomFieldAttributesCommandValidator();

  final ICatalogCustomFieldConfigGateway _customFieldConfigGateway;
  final ConfigureCustomFieldAttributesCommandValidator _validator;

  @override
  Future<ConfigureCustomFieldAttributesResult> handle(
    ConfigureCustomFieldAttributesCommand command,
  ) async {
    await _validator.validate(command);
    return _customFieldConfigGateway.configureAttributes(command: command);
  }
}
