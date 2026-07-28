import 'platform_audit_log_status.dart';

/// Detail DTO for a platform audit log (EP-02/US-10). Sensitive fields are redacted.
final class PlatformAuditLogDetailDto {
  const PlatformAuditLogDetailDto({
    required this.id,
    required this.title,
    required this.actionCode,
    required this.status,
    required this.statusLabel,
    required this.actorName,
    required this.actorRole,
    required this.targetOrgName,
    required this.targetOrgCode,
    required this.timestamp,
    required this.sourceApp,
    required this.correlationId,
    required this.beforeState,
    required this.afterState,
  });

  final String id;
  final String title;
  final String actionCode;
  final PlatformAuditLogStatus status;
  final String statusLabel;
  final String actorName;
  final String actorRole;
  final String targetOrgName;
  final String targetOrgCode;
  final DateTime timestamp;
  final String sourceApp;
  final String correlationId;
  final String beforeState;
  final String afterState;
}
