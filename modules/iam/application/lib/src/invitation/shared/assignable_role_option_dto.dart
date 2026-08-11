/// Assignable role option for invitation create (S7 / D1).
final class AssignableRoleOptionDto {
  const AssignableRoleOptionDto({
    required this.roleId,
    required this.label,
  });

  final String roleId;
  final String label;
}
