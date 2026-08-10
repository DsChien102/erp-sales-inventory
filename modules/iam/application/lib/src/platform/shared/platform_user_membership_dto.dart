/// Membership row shown on Platform User detail (FR-04).
///
/// [isOwner] is independent of [roleLabel] (Owner ≠ role).
final class PlatformUserMembershipDto {
  const PlatformUserMembershipDto({
    required this.tenantId,
    required this.tenantName,
    required this.roleLabel,
    required this.isOwner,
  });

  final String tenantId;
  final String tenantName;
  final String roleLabel;
  final bool isOwner;
}
