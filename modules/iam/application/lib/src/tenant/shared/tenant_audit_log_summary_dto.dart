import 'tenant_audit_log_result.dart';

/// Summary row for tenant audit search (§S13).
final class TenantAuditLogSummaryDto {
  const TenantAuditLogSummaryDto({
    required this.auditLogId,
    required this.eventCode,
    required this.result,
    required this.occurredAt,
    required this.source,
    required this.trackingId,
    this.actorUserId,
    this.actorDisplayName,
    this.subjectType,
    this.subjectId,
  });

  final String auditLogId;
  final String eventCode;
  final TenantAuditLogResult result;
  final DateTime occurredAt;
  final String source;
  final String trackingId;
  final String? actorUserId;
  final String? actorDisplayName;
  final String? subjectType;
  final String? subjectId;
}
