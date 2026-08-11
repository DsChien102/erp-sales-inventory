import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

@RequiresPermission(IamPermissions.membersAssignRole)
@RequiresTenant()
final class AssignMemberRoleCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  AssignMemberRoleCommand({
    String? id,
    required this.tenantId,
    required this.userId,
    required this.role,
  }) : super(id);

  @override
  final String tenantId;
  final String userId;
  final String role;
}
