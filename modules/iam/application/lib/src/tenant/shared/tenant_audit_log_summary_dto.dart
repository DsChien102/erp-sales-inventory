import 'tenant_audit_actor_dto.dart';
import 'tenant_audit_event_category.dart';
import 'tenant_audit_log_result.dart';
import 'tenant_audit_subject_dto.dart';

/// Summary row for tenant audit search (§S13).
final class TenantAuditLogSummaryDto {
  const TenantAuditLogSummaryDto({
    required this.auditLogId,
    required this.eventCode,
    this.eventCategory,
    required this.result,
    required this.occurredAt,
    required this.source,
    required this.trackingId,
    required this.actor,
    required this.subject,
  });

  final String auditLogId;
  final String eventCode;
  final TenantAuditEventCategory? eventCategory;
  final TenantAuditLogResult result;
  final DateTime occurredAt;
  final String source;
  final String trackingId;
  final TenantAuditActorDto actor;
  final TenantAuditSubjectDto subject;
}
