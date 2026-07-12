import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_custom_field_config_gateway.dart';
import 'reorder_custom_fields_command.dart';
import 'reorder_custom_fields_command_validator.dart';

@CommandHandlerFor(ReorderCustomFieldsCommand)
final class ReorderCustomFieldsCommandHandler
    implements ICommandHandler<ReorderCustomFieldsCommand, void> {
  ReorderCustomFieldsCommandHandler({
    required ICatalogCustomFieldConfigGateway customFieldConfigGateway,
    ReorderCustomFieldsCommandValidator? validator,
  }) : _customFieldConfigGateway = customFieldConfigGateway,
       _validator = validator ?? ReorderCustomFieldsCommandValidator();

  final ICatalogCustomFieldConfigGateway _customFieldConfigGateway;
  final ReorderCustomFieldsCommandValidator _validator;

  @override
  Future<void> handle(ReorderCustomFieldsCommand command) async {
    await _validator.validate(command);
    await _customFieldConfigGateway.reorderFields(command: command);
  }
}
