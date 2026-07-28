import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_audit_log_detail_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import 'get_platform_audit_log_query.dart';

@QueryHandlerFor(GetPlatformAuditLogQuery)
final class GetPlatformAuditLogQueryHandler
    implements IQueryHandler<GetPlatformAuditLogQuery, PlatformAuditLogDetailDto> {
  GetPlatformAuditLogQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<PlatformAuditLogDetailDto> handle(GetPlatformAuditLogQuery query) {
    return _platformGateway.getPlatformAuditLog(query.auditLogId);
  }
}
