import 'package:vet45_iam_application/application.dart';

import 'invitation_role_options.dart';

/// Production [InvitationRoleOptionsSource] backed by D1 query.
final class IamModuleInvitationRoleOptionsSource
    implements InvitationRoleOptionsSource {
  IamModuleInvitationRoleOptionsSource({required IIamModule iamModule})
    : _iamModule = iamModule;

  final IIamModule _iamModule;

  @override
  Future<List<InvitationRoleOption>> load(String tenantId) async {
    final rows = await _iamModule
        .executeQueryAsync<List<AssignableRoleOptionDto>>(
          ListAssignableInvitationRolesQuery(tenantId: tenantId),
        );
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
