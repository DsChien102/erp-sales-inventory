import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/cursor_page_dto.dart';
import '../../dto/platform_audit_log_summary_dto.dart';

/// Search / list Platform Audit Logs (EP-02/US-10).
@RequiresPermission(IamPlatformPermissions.auditView)
final class SearchPlatformAuditLogsQuery
    extends QueryBase<CursorPageDto<PlatformAuditLogSummaryDto>>
    implements IQuery<CursorPageDto<PlatformAuditLogSummaryDto>> {
  SearchPlatformAuditLogsQuery({
    String? id,
    this.fromUtc,
    this.toUtc,
    this.actorUserId,
    this.targetType,
    this.targetId,
    this.action,
    this.result,
    this.source,
    this.correlationId,
    this.cursor,
    this.limit = 20,
  }) : super(id);

  final DateTime? fromUtc;
  final DateTime? toUtc;
  final String? actorUserId;
  final String? targetType;
  final String? targetId;
  final String? action;
  final String? result;
  final String? source;
  final String? correlationId;
  final String? cursor;
  final int limit;
}
