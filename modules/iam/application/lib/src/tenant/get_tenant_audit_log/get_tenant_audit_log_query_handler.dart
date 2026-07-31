import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_audit_log_detail_dto.dart';
import '../../ports/i_tenant_audit_read_port.dart';
import '../../shared/iam_blocked_codes.dart';
import '../../shared/iam_blocked_exception.dart';
import 'get_tenant_audit_log_query.dart';

@QueryHandlerFor(GetTenantAuditLogQuery)
final class GetTenantAuditLogQueryHandler
    implements IQueryHandler<GetTenantAuditLogQuery, TenantAuditLogDetailDto> {
  GetTenantAuditLogQueryHandler({
    required ITenantAuditReadPort auditReadPort,
  }) : _auditReadPort = auditReadPort;

  final ITenantAuditReadPort _auditReadPort;

  @override
  Future<TenantAuditLogDetailDto> handle(GetTenantAuditLogQuery query) async {
    final detail = await _auditReadPort.getDetail(
      tenantId: query.tenantId,
      auditLogId: query.auditLogId,
    );
    if (detail == null) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return detail;
  }
}
