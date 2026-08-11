import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_audit_log_detail_dto.dart';

@RequiresPermission(IamPermissions.tenantAuditView)
@RequiresTenant()
final class GetTenantAuditLogQuery extends QueryBase<TenantAuditLogDetailDto>
    implements IQuery<TenantAuditLogDetailDto>, ITenantScopedCommand {
  GetTenantAuditLogQuery({
    String? id,
    required this.tenantId,
    required this.auditLogId,
  }) : super(id);

  @override
  final String tenantId;
  final String auditLogId;
}
