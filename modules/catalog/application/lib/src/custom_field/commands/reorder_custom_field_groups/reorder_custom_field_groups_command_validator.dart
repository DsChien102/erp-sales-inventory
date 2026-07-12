import 'package:vet45_shared_application/application.dart';

import 'reorder_custom_field_groups_command.dart';

final class ReorderCustomFieldGroupsCommandValidator
    implements ICommandValidator<ReorderCustomFieldGroupsCommand> {
  @override
  Future<void> validate(ReorderCustomFieldGroupsCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.orderedGroupIds.isEmpty) {
      throw ValidationException('Ordered group ids must include all groups.');
    }
    for (final groupId in command.orderedGroupIds) {
      if (groupId.trim().isEmpty) {
        throw ValidationException('Group id must not be empty.');
      }
    }
  }
}
