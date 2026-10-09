/// Trạng thái ngữ cảnh tổ chức trả về từ `get_tenant_context` / `switch_tenant_context`.
enum TenantContextStatus { valid, invalidated, none }

/// Lý do ngữ cảnh bị vô hiệu. Giá trị camelCase đúng JSON RPC.
enum TenantContextInvalidationReason {
  membershipRemoved,
  membershipInactive,
  tenantSuspended,
  tenantClosed,
  accessDenied,
  identityInactive,
  roleNoLongerAssignable,
  permissionsChanged,
  ownershipChanged,
}

/// Vòng đời tổ chức. Giá trị lạ map về [active], như gateway cũ.
enum TenantStatus { active, provisioning, suspended, closed }

TenantStatus tenantStatusFromWire(String? raw) {
  return switch (raw) {
    'provisioning' => TenantStatus.provisioning,
    'suspended' => TenantStatus.suspended,
    'closed' => TenantStatus.closed,
    _ => TenantStatus.active,
  };
}

/// Kết quả `get_tenant_context` / `switch_tenant_context`.
final class TenantContext {
  const TenantContext({
    this.status = TenantContextStatus.none,
    this.tenantId,
    this.tenantName,
    this.roleLabel,
    this.isOwner = false,
    this.permissions = const [],
    this.tenantStatus,
    this.invalidationReason,
    this.blockedErrorCode,
  });

  static const none = TenantContext();

  final TenantContextStatus status;
  final String? tenantId;
  final String? tenantName;

  /// Giá trị cột `role` (chưa đổi sang nhãn hiển thị).
  final String? roleLabel;
  final bool isOwner;
  final List<String> permissions;
  final TenantStatus? tenantStatus;
  final TenantContextInvalidationReason? invalidationReason;
  final String? blockedErrorCode;

  factory TenantContext.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return none;

    final status = switch (json['status'] as String? ?? 'none') {
      'valid' => TenantContextStatus.valid,
      'invalidated' => TenantContextStatus.invalidated,
      _ => TenantContextStatus.none,
    };

    final tenantStatusRaw = json['tenant_status'] as String?;
    return TenantContext(
      status: status,
      tenantId: json['tenant_id'] as String?,
      tenantName: json['tenant_name'] as String?,
      roleLabel: json['role'] as String?,
      isOwner: json['is_owner'] as bool? ?? false,
      permissions: _stringList(json['permissions']),
      tenantStatus: tenantStatusRaw == null ? null : tenantStatusFromWire(tenantStatusRaw),
      invalidationReason: _invalidationReason(json['invalidation_reason'] as String?),
      blockedErrorCode: json['blocked_error_code'] as String?,
    );
  }
}

TenantContextInvalidationReason? _invalidationReason(String? raw) {
  return switch (raw) {
    'membershipRemoved' => TenantContextInvalidationReason.membershipRemoved,
    'membershipInactive' => TenantContextInvalidationReason.membershipInactive,
    'tenantSuspended' => TenantContextInvalidationReason.tenantSuspended,
    'tenantClosed' => TenantContextInvalidationReason.tenantClosed,
    'accessDenied' => TenantContextInvalidationReason.accessDenied,
    'identityInactive' => TenantContextInvalidationReason.identityInactive,
    'roleNoLongerAssignable' => TenantContextInvalidationReason.roleNoLongerAssignable,
    'permissionsChanged' => TenantContextInvalidationReason.permissionsChanged,
    'ownershipChanged' => TenantContextInvalidationReason.ownershipChanged,
    _ => null,
  };
}

List<String> _stringList(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((item) => item as String).toList(growable: false);
}
