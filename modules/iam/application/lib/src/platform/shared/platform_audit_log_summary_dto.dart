import 'platform_audit_log_status.dart';

/// List-row DTO for platform audit search (EP-02/US-10).
final class PlatformAuditLogSummaryDto {
  const PlatformAuditLogSummaryDto({
    required this.id,
    required this.title,
    required this.actionCode,
    required this.status,
    required this.actorName,
    required this.actorRole,
    required this.targetOrgName,
    required this.targetOrgCode,
    required this.timestamp,
    required this.sourceApp,
  });

  final String id;
  final String title;
  final String actionCode;
  final PlatformAuditLogStatus status;
  final String actorName;
  final String actorRole;
  final String targetOrgName;
  final String targetOrgCode;
  final DateTime timestamp;
  final String sourceApp;
}
