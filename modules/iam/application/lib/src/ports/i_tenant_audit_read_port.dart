import '../dto/tenant_audit_log_detail_dto.dart';
import '../dto/tenant_audit_log_search_page_dto.dart';

/// Platform Audit read port for tenant-scoped history (§S13).
abstract interface class ITenantAuditReadPort {
  Future<TenantAuditLogSearchPageDto> search({
    required String tenantId,
    required DateTime from,
    required DateTime to,
    String? result,
    String? actorUserId,
    String? subjectType,
    String? eventCode,
    String? cursor,
    int? limit,
  });

  Future<TenantAuditLogDetailDto?> getDetail({
    required String tenantId,
    required String auditLogId,
  });
}
