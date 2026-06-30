/// Tenant member row for list queries.
final class TenantMemberDto {
  const TenantMemberDto({
    required this.userId,
    required this.role,
    required this.createdAt,
  });

  final String userId;
  final String role;
  final DateTime createdAt;
}
