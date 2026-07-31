import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_audit_log_search_page_dto.dart';
import '../../ports/i_tenant_audit_read_port.dart';
import '../../shared/iam_blocked_codes.dart';
import '../../shared/iam_blocked_exception.dart';
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
    if (query.fromUtc.isAfter(query.toUtc)) {
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
      result: query.result,
      actorUserId: query.actorUserId,
      subjectType: query.subjectType,
      eventCode: query.eventCode,
      cursor: query.cursor,
      limit: limit,
    );
  }
}
