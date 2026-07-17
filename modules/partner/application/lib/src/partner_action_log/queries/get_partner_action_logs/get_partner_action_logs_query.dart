import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_action_log_result_dto.dart';

@RequiresPermission(PartnerPermissions.detailView)
@RequiresTenant()
final class GetPartnerActionLogsQuery extends QueryBase<PartnerActionLogResultDto>
    implements IQuery<PartnerActionLogResultDto>, ITenantScopedCommand {
  GetPartnerActionLogsQuery({
    String? id,
    required this.tenantId,
    required this.partnerId,
    this.page = 1,
    this.limit = 20,
  }) : super(id);

  @override
  final String tenantId;
  final String partnerId;
  final int page;
  final int limit;
}
