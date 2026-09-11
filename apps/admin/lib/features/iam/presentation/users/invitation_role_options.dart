/// Presentation role option for invitation create (S7 / D1).
final class InvitationRoleOption {
  const InvitationRoleOption({
    required this.roleId,
    required this.label,
  });

  final String roleId;
  final String label;
}

/// Loads assignable roles for the invite form. Production binds to
/// [ListAssignableInvitationRolesQuery]; tests may inject a fake source.
abstract interface class InvitationRoleOptionsSource {
  Future<List<InvitationRoleOption>> load(String tenantId);
}
