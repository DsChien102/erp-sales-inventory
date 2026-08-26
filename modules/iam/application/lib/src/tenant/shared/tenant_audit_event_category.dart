/// Canonical event category for tenant audit logs (§S13).
enum TenantAuditEventCategory {
  member('member'),
  role('role'),
  organization('organization'),
  invitation('invitation'),
  account('account'),
  security('security'),
  system('system');

  const TenantAuditEventCategory(this.code);

  final String code;

  static TenantAuditEventCategory? fromCode(String? code) {
    if (code == null) return null;
    for (final category in values) {
      if (category.code == code) return category;
    }
    return null;
  }
}
