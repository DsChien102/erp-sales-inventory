import 'package:vet45_shared_application/application.dart';

import '../../dto/cursor_page_dto.dart';
import '../../dto/platform_audit_log_summary_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import '../../shared/iam_blocked_codes.dart';
import '../../shared/iam_blocked_exception.dart';
import 'search_platform_audit_logs_query.dart';

@QueryHandlerFor(SearchPlatformAuditLogsQuery)
final class SearchPlatformAuditLogsQueryHandler
    implements
        IQueryHandler<
          SearchPlatformAuditLogsQuery,
          CursorPageDto<PlatformAuditLogSummaryDto>
        > {
  SearchPlatformAuditLogsQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<CursorPageDto<PlatformAuditLogSummaryDto>> handle(
    SearchPlatformAuditLogsQuery query,
  ) {
    if (query.limit < 1 || query.limit > 100) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    if (query.fromUtc != null &&
        query.toUtc != null &&
        query.fromUtc!.isAfter(query.toUtc!)) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    return _platformGateway.searchPlatformAuditLogs(
      fromUtc: query.fromUtc,
      toUtc: query.toUtc,
      actorUserId: query.actorUserId,
      targetType: query.targetType,
      targetId: query.targetId,
      action: query.action,
      result: query.result,
      source: query.source,
      correlationId: query.correlationId,
      cursor: query.cursor,
      limit: query.limit,
    );
  }
}
