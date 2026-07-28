import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_audit_log_detail_dto.dart';

/// Get Platform Audit Log detail (EP-02/US-10).
@RequiresPermission(IamPlatformPermissions.auditView)
final class GetPlatformAuditLogQuery
    extends QueryBase<PlatformAuditLogDetailDto>
    implements IQuery<PlatformAuditLogDetailDto> {
  GetPlatformAuditLogQuery({
    String? id,
    required this.auditLogId,
  }) : super(id);

  final String auditLogId;
}
