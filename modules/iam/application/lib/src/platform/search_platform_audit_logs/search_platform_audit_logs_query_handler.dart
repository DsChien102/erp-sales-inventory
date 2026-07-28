import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_audit_log_summary_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import 'search_platform_audit_logs_query.dart';

@QueryHandlerFor(SearchPlatformAuditLogsQuery)
final class SearchPlatformAuditLogsQueryHandler
    implements
        IQueryHandler<
          SearchPlatformAuditLogsQuery,
          List<PlatformAuditLogSummaryDto>
        > {
  SearchPlatformAuditLogsQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<List<PlatformAuditLogSummaryDto>> handle(
    SearchPlatformAuditLogsQuery query,
  ) {
    return _platformGateway.searchPlatformAuditLogs(
      query: query.query,
      status: query.status,
    );
  }
}
