import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/cursor_page_dto.dart';
import '../../shared/invitation_summary_dto.dart';

@RequiresPermission(IamPermissions.memberView)
@RequiresTenant()
final class ListInvitationsQuery
    extends QueryBase<CursorPageDto<InvitationSummaryDto>>
    implements
        IQuery<CursorPageDto<InvitationSummaryDto>>,
        ITenantScopedCommand {
  ListInvitationsQuery({
    String? id,
    required this.tenantId,
    this.search,
    this.status,
    this.cursor,
    this.limit = 20,
  }) : super(id);

  @override
  final String tenantId;
  final String? search;

  /// `pending` | `accepted` | `declined` | `revoked` | `expired`.
  final String? status;
  final String? cursor;
  final int limit;
}
