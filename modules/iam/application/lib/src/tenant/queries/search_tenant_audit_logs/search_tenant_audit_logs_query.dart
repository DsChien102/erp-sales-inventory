import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_audit_event_category.dart';
import '../../shared/tenant_audit_log_search_page_dto.dart';

@RequiresPermission(IamPermissions.tenantAuditView)
@RequiresTenant()
final class SearchTenantAuditLogsQuery extends QueryBase<TenantAuditLogSearchPageDto>
    implements IQuery<TenantAuditLogSearchPageDto>, ITenantScopedCommand {
  SearchTenantAuditLogsQuery({
    String? id,
    required this.tenantId,
    required this.fromUtc,
    required this.toUtc,
    this.query,
    this.result,
    this.eventCategory,
    this.subjectType,
    this.eventCodes,
    this.cursor,
    this.limit,
  }) : super(id);

  @override
  final String tenantId;
  final DateTime fromUtc;
  final DateTime toUtc;
  final String? query;
  final String? result;
  final TenantAuditEventCategory? eventCategory;
  final String? subjectType;
  final List<String>? eventCodes;
  final String? cursor;
  final int? limit;
}
