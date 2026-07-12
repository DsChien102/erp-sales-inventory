import 'package:vet45_shared_application/application.dart';

import 'upsert_custom_field_group_command.dart';

final class UpsertCustomFieldGroupCommandValidator
    implements ICommandValidator<UpsertCustomFieldGroupCommand> {
  @override
  Future<void> validate(UpsertCustomFieldGroupCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.name.trim().isEmpty) {
      throw ValidationException('Group name must not be empty.');
    }
  }
}
