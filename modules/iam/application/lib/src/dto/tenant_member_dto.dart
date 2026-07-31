/// Tenant member row for S6 list queries.
final class TenantMemberDto {
  const TenantMemberDto({
    required this.membershipId,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.roleId,
    required this.roleLabel,
    required this.isOwner,
    required this.status,
    required this.joinedAt,
    required this.version,
  });

  final String membershipId;
  final String userId;
  final String displayName;
  final String email;
  final String roleId;
  final String roleLabel;
  final bool isOwner;

  /// Wire: `active` | `inactive` | `removed`.
  final String status;
  final DateTime joinedAt;
  final int version;
}
