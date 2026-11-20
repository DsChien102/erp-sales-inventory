/// Ảnh phiên cho UI và router: người dùng, tổ chức, cửa hàng, vai trò, quyền.
///
/// Chủ sở hữu (`isOwner`) luôn có mọi quyền, độc lập với [role].
final class SessionSnapshot {
  const SessionSnapshot({
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
  final bool isOwner;
  final List<String> permissions;

  bool hasPermission(String code) => isOwner || permissions.contains(code);
}
