/// Tenant membership row for the current user.
final class TenantMembershipDto {
  const TenantMembershipDto({
    required this.tenantId,
    required this.name,
    required this.role,
  });

  final String tenantId;
  final String name;
  final String role;
}
