import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/cursor_page_dto.dart';
import '../../dto/tenant_member_dto.dart';

@RequiresPermission(IamPermissions.memberView)
@RequiresTenant()
final class ListTenantMembersQuery
    extends QueryBase<CursorPageDto<TenantMemberDto>>
    implements IQuery<CursorPageDto<TenantMemberDto>>, ITenantScopedCommand {
  ListTenantMembersQuery({
    String? id,
    required this.tenantId,
    this.search,
    this.status,
    this.cursor,
    this.limit = 20,
  }) : super(id);

  @override
  final String tenantId;

  /// Trimmed canonical email/name search; empty/null = no filter.
  final String? search;

  /// `active` | `inactive` | `removed`.
  final String? status;
  final String? cursor;
  final int limit;
}
