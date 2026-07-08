import 'package:vet45_shared_application/application.dart';

import '../../ports/i_catalog_custom_field_config_gateway.dart';
import '../shared/custom_field_group_config_dto.dart';
import 'upsert_custom_field_group_command.dart';
import 'upsert_custom_field_group_command_validator.dart';

@CommandHandlerFor(UpsertCustomFieldGroupCommand)
final class UpsertCustomFieldGroupCommandHandler
    implements
        ICommandHandler<UpsertCustomFieldGroupCommand, CustomFieldGroupConfigDto> {
  UpsertCustomFieldGroupCommandHandler({
    required ICatalogCustomFieldConfigGateway customFieldConfigGateway,
    UpsertCustomFieldGroupCommandValidator? validator,
  }) : _customFieldConfigGateway = customFieldConfigGateway,
       _validator = validator ?? UpsertCustomFieldGroupCommandValidator();

  final ICatalogCustomFieldConfigGateway _customFieldConfigGateway;
  final UpsertCustomFieldGroupCommandValidator _validator;

  @override
  Future<CustomFieldGroupConfigDto> handle(
    UpsertCustomFieldGroupCommand command,
  ) async {
    await _validator.validate(command);
    return _customFieldConfigGateway.upsertGroup(command: command);
  }
}
