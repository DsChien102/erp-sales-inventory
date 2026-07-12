import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_custom_field_config_gateway.dart';
import 'reorder_custom_field_groups_command.dart';
import 'reorder_custom_field_groups_command_validator.dart';

@CommandHandlerFor(ReorderCustomFieldGroupsCommand)
final class ReorderCustomFieldGroupsCommandHandler
    implements ICommandHandler<ReorderCustomFieldGroupsCommand, void> {
  ReorderCustomFieldGroupsCommandHandler({
    required ICatalogCustomFieldConfigGateway customFieldConfigGateway,
    ReorderCustomFieldGroupsCommandValidator? validator,
  }) : _customFieldConfigGateway = customFieldConfigGateway,
       _validator = validator ?? ReorderCustomFieldGroupsCommandValidator();

  final ICatalogCustomFieldConfigGateway _customFieldConfigGateway;
  final ReorderCustomFieldGroupsCommandValidator _validator;

  @override
  Future<void> handle(ReorderCustomFieldGroupsCommand command) async {
    await _validator.validate(command);
    await _customFieldConfigGateway.reorderGroups(command: command);
  }
}
