import 'package:vet45_shared_application/application.dart';

import '../../ports/i_iam_access_gateway.dart';
import 'assign_member_role_command.dart';

@CommandHandlerFor(AssignMemberRoleCommand)
final class AssignMemberRoleCommandHandler
    implements ICommandHandler<AssignMemberRoleCommand, void> {
  AssignMemberRoleCommandHandler({required IIamAccessGateway accessGateway})
    : _accessGateway = accessGateway;

  final IIamAccessGateway _accessGateway;

  @override
  Future<void> handle(AssignMemberRoleCommand command) {
    return _accessGateway.assignMemberRole(
      tenantId: command.tenantId,
      userId: command.userId,
      role: command.role,
    );
  }
}
