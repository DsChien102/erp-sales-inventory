/// Presentation-safe session snapshot.
final class SessionDto {
  const SessionDto({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.tenantId,
    this.activeStoreId,
    this.role,
    this.isOwner = false,
    this.permissions = const [],
  });

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? tenantId;
  final String? activeStoreId;
  final String? role;

  /// Ownership is orthogonal to [role] (Owner ≠ role); owner keeps full bypass.
  final bool isOwner;
  final List<String> permissions;

  bool hasPermission(String code) => isOwner || permissions.contains(code);
}
