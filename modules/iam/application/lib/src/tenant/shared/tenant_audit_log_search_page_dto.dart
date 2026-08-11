import 'tenant_audit_log_summary_dto.dart';

/// Cursor-paginated tenant audit search result (§S13).
final class TenantAuditLogSearchPageDto {
  const TenantAuditLogSearchPageDto({
    required this.items,
    this.nextCursor,
  });

  final List<TenantAuditLogSummaryDto> items;
  final String? nextCursor;
}
