/// Principal access resolved from IAM session context RPC.
final class PrincipalAccessDto {
  const PrincipalAccessDto({
    required this.userId,
    required this.tenantId,
    required this.role,
    required this.permissions,
  });

  final String userId;
  final String tenantId;
  final String role;
  final List<String> permissions;
}
