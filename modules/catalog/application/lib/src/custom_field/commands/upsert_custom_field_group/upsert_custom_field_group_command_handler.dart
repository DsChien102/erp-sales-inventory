import 'package:uuid/uuid.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_custom_field_config_gateway.dart';
import 'package:vet45_catalog_application/src/custom_field/shared/custom_field_group_config_dto.dart';
import 'upsert_custom_field_group_command.dart';
import 'upsert_custom_field_group_command_validator.dart';

@CommandHandlerFor(UpsertCustomFieldGroupCommand)
final class UpsertCustomFieldGroupCommandHandler
    implements ICommandHandler<UpsertCustomFieldGroupCommand, CustomFieldGroupConfigDto> {
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

    // Domain-first: validate group name before RPC.
    CustomFieldGroup.create(
      id: command.groupId ?? const Uuid().v4(),
      tenantId: command.tenantId,
      name: command.name,
      icon: command.iconKey,
    );

    return _customFieldConfigGateway.upsertGroup(command: command);
  }
}
