import 'tenant_audit_log_result.dart';

/// Detail row for a tenant audit log (§S13).
final class TenantAuditLogDetailDto {
  const TenantAuditLogDetailDto({
    required this.auditLogId,
    required this.tenantId,
    required this.eventCode,
    required this.result,
    required this.occurredAt,
    required this.source,
    required this.trackingId,
    required this.actorUnavailable,
    required this.beforeRedacted,
    required this.afterRedacted,
    this.actorUserId,
    this.actorDisplayName,
    this.subjectType,
    this.subjectId,
    this.beforeState,
    this.afterState,
  });

  final String auditLogId;
  final String tenantId;
  final String eventCode;
  final TenantAuditLogResult result;
  final DateTime occurredAt;
  final String source;
  final String trackingId;
  final bool actorUnavailable;
  final bool beforeRedacted;
  final bool afterRedacted;
  final String? actorUserId;
  final String? actorDisplayName;
  final String? subjectType;
  final String? subjectId;
  final String? beforeState;
  final String? afterState;
}
