import '../../data/invitation_repository.dart';
import '../../logic/invitation_role_options.dart';

/// Production [InvitationRoleOptionsSource] backed by `list_assignable_invitation_roles`.
final class IamModuleInvitationRoleOptionsSource
    implements InvitationRoleOptionsSource {
  IamModuleInvitationRoleOptionsSource({required InvitationRepository invitations})
    : _invitations = invitations;

  final InvitationRepository _invitations;

  @override
  Future<List<InvitationRoleOption>> load(String tenantId) async {
    final rows = await _invitations.listAssignableRoles();
    return rows
        .map(
          (row) => InvitationRoleOption(
            roleId: row.roleId,
            label: row.label,
          ),
        )
        .toList(growable: false);
  }
}
