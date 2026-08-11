/// Membership row for a platform tenant (EP-02/US-08).
final class PlatformTenantMemberDto {
  const PlatformTenantMemberDto({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.roleLabel,
    required this.isOwner,
  });

  final String userId;
  final String fullName;
  final String email;
  final String roleLabel;
  final bool isOwner;
}
