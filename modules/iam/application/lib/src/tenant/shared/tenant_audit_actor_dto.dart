import 'tenant_audit_display_origin.dart';

/// Normalized actor DTO for tenant audit logs (§S13).
final class TenantAuditActorDto {
  const TenantAuditActorDto({
    this.userId,
    this.displayName,
    this.actorType,
    this.roleCode,
    this.roleLabel,
    this.displayOrigin,
  });

  final String? userId;
  final String? displayName;
  final String? actorType;
  final String? roleCode;
  final String? roleLabel;
  final TenantAuditDisplayOrigin? displayOrigin;
}
