/// Audit log result for tenant-scoped events (§S13).
enum TenantAuditLogResult {
  success,
  blocked,
  error,
}

extension TenantAuditLogResultCodes on TenantAuditLogResult {
  String get code => switch (this) {
    TenantAuditLogResult.success => 'success',
    TenantAuditLogResult.blocked => 'blocked',
    TenantAuditLogResult.error => 'error',
  };

  static TenantAuditLogResult? fromCode(String? raw) => switch (raw) {
    'success' => TenantAuditLogResult.success,
    'blocked' => TenantAuditLogResult.blocked,
    'error' => TenantAuditLogResult.error,
    _ => null,
  };
}
