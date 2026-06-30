import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'assign_member_role_command.dart';

final class AssignMemberRoleCommandValidator
    implements ICommandValidator<AssignMemberRoleCommand> {
  @override
  Future<void> validate(AssignMemberRoleCommand command) async {
    AssignMemberRoleRules.ensureRoleAllowed(command.role);
  }
}
