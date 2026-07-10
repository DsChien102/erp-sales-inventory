import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/partner_transaction_type.dart';
import 'partner_history_result_dto.dart';

@RequiresPermission(PartnerPermissions.historyView)
@RequiresTenant()
final class GetPartnerHistoryQuery extends QueryBase<PartnerHistoryResultDto>
    implements IQuery<PartnerHistoryResultDto>, ITenantScopedCommand {
  GetPartnerHistoryQuery({
    String? id,
    required this.tenantId,
    required this.partnerId,
    this.role,
    this.transactionType,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 20,
  }) : super(id);

  @override
  final String tenantId;
  final String partnerId;
  final PartnerRoleType? role;
  final PartnerTransactionType? transactionType;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int limit;
}
