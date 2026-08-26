/// Display provenance for audit actors and subjects (§S13).
enum TenantAuditDisplayOrigin {
  snapshot('snapshot'),
  current('current'),
  system('system'),
  unavailable('unavailable');

  const TenantAuditDisplayOrigin(this.code);

  final String code;

  static TenantAuditDisplayOrigin? fromCode(String? code) {
    if (code == null) return null;
    for (final origin in values) {
      if (origin.code == code) return origin;
    }
    return null;
  }
}
