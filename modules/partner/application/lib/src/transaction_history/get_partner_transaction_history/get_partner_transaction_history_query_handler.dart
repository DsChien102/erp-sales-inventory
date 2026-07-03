import 'package:vet45_shared_application/application.dart';

import '../../ports/i_partner_transaction_history_read_gateway.dart';
import 'get_partner_transaction_history_query.dart';
import 'partner_transaction_history_result_dto.dart';

@QueryHandlerFor(GetPartnerTransactionHistoryQuery)
final class GetPartnerTransactionHistoryQueryHandler
    implements
        IQueryHandler<
          GetPartnerTransactionHistoryQuery,
          PartnerTransactionHistoryResultDto
        > {
  GetPartnerTransactionHistoryQueryHandler({
    required IPartnerTransactionHistoryReadGateway readGateway,
  }) : _readGateway = readGateway;

  final IPartnerTransactionHistoryReadGateway _readGateway;

  @override
  Future<PartnerTransactionHistoryResultDto> handle(
    GetPartnerTransactionHistoryQuery query,
  ) {
    return _readGateway.list(
      tenantId: query.tenantId,
      partnerId: query.partnerId,
      criteria: query.criteria,
      limit: query.limit,
      offset: query.offset,
    );
  }
}
