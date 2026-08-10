import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/assignable_role_option_dto.dart';

/// Lists active roles that may be used as `initialRoleId` on invite (S7 / D1).
@RequiresPermission(IamPermissions.memberInvite)
@RequiresTenant()
final class ListAssignableInvitationRolesQuery
    extends QueryBase<List<AssignableRoleOptionDto>>
    implements
        IQuery<List<AssignableRoleOptionDto>>,
        ITenantScopedCommand {
  ListAssignableInvitationRolesQuery({
    String? id,
    required this.tenantId,
  }) : super(id);

  @override
  final String tenantId;
}
