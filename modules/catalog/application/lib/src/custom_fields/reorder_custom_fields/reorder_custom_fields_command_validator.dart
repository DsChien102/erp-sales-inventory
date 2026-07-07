import 'package:vet45_shared_application/application.dart';

import 'reorder_custom_fields_command.dart';

final class ReorderCustomFieldsCommandValidator
    implements ICommandValidator<ReorderCustomFieldsCommand> {
  @override
  Future<void> validate(ReorderCustomFieldsCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.groupId.trim().isEmpty) {
      throw ValidationException('Group id is required.');
    }
    if (command.orderedFieldIds.isEmpty) {
      throw ValidationException('Ordered field ids must include all fields.');
    }
    for (final fieldId in command.orderedFieldIds) {
      if (fieldId.trim().isEmpty) {
        throw ValidationException('Field id must not be empty.');
      }
    }
  }
}
