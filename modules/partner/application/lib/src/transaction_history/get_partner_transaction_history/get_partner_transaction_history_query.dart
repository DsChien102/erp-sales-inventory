import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_transaction_history_result_dto.dart';

@RequiresPermission(PartnerPermissions.viewTransactionHistory)
@RequiresTenant()
final class GetPartnerTransactionHistoryQuery
    extends QueryBase<PartnerTransactionHistoryResultDto> {
  GetPartnerTransactionHistoryQuery({
    String? id,
    required this.tenantId,
    required this.partnerId,
    required this.criteria,
    this.limit = 100,
    this.offset = 0,
  }) : super(id);

  final String tenantId;
  final String partnerId;
  final PartnerTransactionHistoryCriteria criteria;
  final int limit;
  final int offset;
}
