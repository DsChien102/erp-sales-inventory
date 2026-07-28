import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_audit_log_status.dart';
import '../../dto/platform_audit_log_summary_dto.dart';

/// Search / list Platform Audit Logs (EP-02/US-10).
@RequiresPermission(IamPlatformPermissions.auditView)
final class SearchPlatformAuditLogsQuery
    extends QueryBase<List<PlatformAuditLogSummaryDto>>
    implements IQuery<List<PlatformAuditLogSummaryDto>> {
  SearchPlatformAuditLogsQuery({
    String? id,
    this.query,
    this.status,
  }) : super(id);

  final String? query;
  final PlatformAuditLogStatus? status;
}
