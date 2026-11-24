/// Kết quả `get_session_context`: người dùng, tổ chức và cửa hàng đang hoạt động.
final class SessionPrincipal {
  const SessionPrincipal({
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
  final bool isOwner;
  final List<String> permissions;

  factory SessionPrincipal.fromJson(Map<String, dynamic> json) {
    final permissionsRaw = json['permissions'];
    final permissions = switch (permissionsRaw) {
      final List<dynamic> list => list.map((item) => item as String).toList(growable: false),
      _ => const <String>[],
    };
    return SessionPrincipal(
      userId: json['user_id'] as String,
      tenantId: json['tenant_id'] as String,
      activeStoreId: _optionalId(json['active_store_id']),
      activeStoreCode: _optionalId(json['active_store_code']),
      activeStoreDisplayName: _optionalId(json['active_store_display_name']),
      role: json['role'] as String,
      isOwner: json['is_owner'] as bool? ?? false,
      permissions: permissions,
    );
  }
}

String? _optionalId(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
