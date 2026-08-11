import 'package:vet45_shared_application/application.dart';

import '../../shared/assignable_role_option_dto.dart';
import '../../../ports/i_assignable_invitation_role_read_port.dart';
import 'list_assignable_invitation_roles_query.dart';

@QueryHandlerFor(ListAssignableInvitationRolesQuery)
final class ListAssignableInvitationRolesQueryHandler
    implements
        IQueryHandler<
          ListAssignableInvitationRolesQuery,
          List<AssignableRoleOptionDto>
        > {
  ListAssignableInvitationRolesQueryHandler({
    required IAssignableInvitationRoleReadPort readPort,
  }) : _readPort = readPort;

  final IAssignableInvitationRoleReadPort _readPort;

  @override
  Future<List<AssignableRoleOptionDto>> handle(
    ListAssignableInvitationRolesQuery query,
  ) {
    return _readPort.listAssignableRoles(tenantId: query.tenantId);
  }
}
