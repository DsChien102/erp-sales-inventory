import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'upsert_custom_field_command.dart';

final class UpsertCustomFieldCommandValidator
    implements ICommandValidator<UpsertCustomFieldCommand> {
  @override
  Future<void> validate(UpsertCustomFieldCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.groupId.trim().isEmpty) {
      throw ValidationException('Group id is required.');
    }
    if (command.name.trim().isEmpty) {
      throw ValidationException('Field name must not be empty.');
    }
    if (command.fieldType == CustomFieldType.singleSelect &&
        command.options.isEmpty &&
        command.fieldId == null) {
      throw ValidationException('Single select field requires options.');
    }
  }
}
