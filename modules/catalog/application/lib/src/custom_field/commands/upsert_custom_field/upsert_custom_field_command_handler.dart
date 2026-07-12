import 'package:uuid/uuid.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_custom_field_config_gateway.dart';
import 'package:vet45_catalog_application/src/custom_field/shared/custom_field_definition_dto.dart';
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

    // Domain-first: validate name / single-select options before RPC.
    CustomField.create(
      id: command.fieldId ?? const Uuid().v4(),
      groupId: command.groupId,
      tenantId: command.tenantId,
      name: command.name,
      fieldType: command.fieldType,
      options: command.options.map((o) => o.label).toList(growable: false),
    );

    return _customFieldConfigGateway.upsertField(command: command);
  }
}
