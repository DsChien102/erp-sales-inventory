import 'tenant_audit_actor_dto.dart';
import 'tenant_audit_event_category.dart';
import 'tenant_audit_log_result.dart';
import 'tenant_audit_subject_dto.dart';

/// Detail row for a tenant audit log (§S13).
final class TenantAuditLogDetailDto {
  const TenantAuditLogDetailDto({
    required this.auditLogId,
    this.auditDisplayId,
    required this.tenantId,
    this.activityCode,
    required this.eventCode,
    this.eventCategory,
    this.titleSnapshot,
    required this.result,
    required this.occurredAt,
    required this.source,
    this.correlationId,
    required this.trackingId,
    required this.actorUnavailable,
    required this.beforeRedacted,
    required this.afterRedacted,
    required this.actor,
    required this.subject,
    this.beforeState,
    this.afterState,
  });

  final String auditLogId;
  final String? auditDisplayId;
  final String tenantId;
  final String? activityCode;
  final String eventCode;
  final TenantAuditEventCategory? eventCategory;
  final String? titleSnapshot;
  final TenantAuditLogResult result;
  final DateTime occurredAt;
  final String source;
  final String? correlationId;
  final String trackingId;
  final bool actorUnavailable;
  final bool beforeRedacted;
  final bool afterRedacted;
  final TenantAuditActorDto actor;
  final TenantAuditSubjectDto subject;
  final Map<String, Object?>? beforeState;
  final Map<String, Object?>? afterState;
}
