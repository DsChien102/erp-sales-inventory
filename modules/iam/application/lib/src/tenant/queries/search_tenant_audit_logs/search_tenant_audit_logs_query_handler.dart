import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_audit_log_search_page_dto.dart';
import '../../../ports/i_tenant_audit_read_port.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import 'search_tenant_audit_logs_query.dart';

@QueryHandlerFor(SearchTenantAuditLogsQuery)
final class SearchTenantAuditLogsQueryHandler
    implements IQueryHandler<SearchTenantAuditLogsQuery, TenantAuditLogSearchPageDto> {
  SearchTenantAuditLogsQueryHandler({
    required ITenantAuditReadPort auditReadPort,
  }) : _auditReadPort = auditReadPort;

  final ITenantAuditReadPort _auditReadPort;

  @override
  Future<TenantAuditLogSearchPageDto> handle(
    SearchTenantAuditLogsQuery query,
  ) async {
    if (!query.fromUtc.isBefore(query.toUtc)) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    final limit = query.limit ?? 20;
    if (limit < 1 || limit > 100) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    return _auditReadPort.search(
      tenantId: query.tenantId,
      from: query.fromUtc,
      to: query.toUtc,
      query: query.query,
      result: query.result,
      eventCategory: query.eventCategory,
      subjectType: query.subjectType,
      eventCodes: query.eventCodes,
      cursor: query.cursor,
      limit: limit,
    );
  }
}
