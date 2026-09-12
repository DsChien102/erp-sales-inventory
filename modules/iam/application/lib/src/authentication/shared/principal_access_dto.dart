/// Principal access resolved from IAM session context RPC.
final class PrincipalAccessDto {
  const PrincipalAccessDto({
    required this.userId,
    required this.tenantId,
    this.activeStoreId,
    this.activeStoreCode,
    this.activeStoreDisplayName,
    required this.role,
    required this.isOwner,
    required this.permissions,
  });

  final String userId;
  final String tenantId;
  final String? activeStoreId;
  final String? activeStoreCode;
  final String? activeStoreDisplayName;
  final String role;

  /// Ownership is an independent admin authorization layer (Owner ≠ role).
  final bool isOwner;
  final List<String> permissions;
}
