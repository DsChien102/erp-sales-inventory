import 'tenant_audit_display_origin.dart';

/// Normalized subject DTO for tenant audit logs (§S13).
final class TenantAuditSubjectDto {
  const TenantAuditSubjectDto({
    this.type,
    this.id,
    this.displayName,
    this.code,
    this.secondaryLabel,
    this.displayOrigin,
  });

  final String? type;
  final String? id;
  final String? displayName;
  final String? code;
  final String? secondaryLabel;
  final TenantAuditDisplayOrigin? displayOrigin;
}
