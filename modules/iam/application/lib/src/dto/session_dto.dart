/// Presentation-safe session snapshot.
final class SessionDto {
  const SessionDto({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.tenantId,
    this.role,
    this.permissions = const [],
  });

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? tenantId;
  final String? role;
  final List<String> permissions;

  bool hasPermission(String code) =>
      role == 'owner' || permissions.contains(code);
}
