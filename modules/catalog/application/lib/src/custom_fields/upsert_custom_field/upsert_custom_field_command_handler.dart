import 'package:vet45_shared_application/application.dart';

import '../../ports/i_catalog_custom_field_config_gateway.dart';
import '../shared/custom_field_definition_dto.dart';
import 'upsert_custom_field_command.dart';
import 'upsert_custom_field_command_validator.dart';

@CommandHandlerFor(UpsertCustomFieldCommand)
final class UpsertCustomFieldCommandHandler
    implements ICommandHandler<UpsertCustomFieldCommand, CustomFieldDefinitionDto> {
  UpsertCustomFieldCommandHandler({
    required ICatalogCustomFieldConfigGateway customFieldConfigGateway,
    UpsertCustomFieldCommandValidator? validator,
  }) : _customFieldConfigGateway = customFieldConfigGateway,
       _validator = validator ?? UpsertCustomFieldCommandValidator();

  final ICatalogCustomFieldConfigGateway _customFieldConfigGateway;
  final UpsertCustomFieldCommandValidator _validator;

  @override
  Future<CustomFieldDefinitionDto> handle(UpsertCustomFieldCommand command) async {
    await _validator.validate(command);
    return _customFieldConfigGateway.upsertField(command: command);
  }
}
