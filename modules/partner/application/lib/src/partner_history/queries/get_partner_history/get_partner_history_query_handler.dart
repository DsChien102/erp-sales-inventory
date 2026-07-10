import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_partner_read_gateway.dart';
import 'get_partner_history_query.dart';
import 'partner_history_result_dto.dart';

@QueryHandlerFor(GetPartnerHistoryQuery)
final class GetPartnerHistoryQueryHandler
    implements IQueryHandler<GetPartnerHistoryQuery, PartnerHistoryResultDto> {
  GetPartnerHistoryQueryHandler({required IPartnerReadGateway readGateway})
    : _readGateway = readGateway;

  final IPartnerReadGateway _readGateway;

  @override
  Future<PartnerHistoryResultDto> handle(GetPartnerHistoryQuery query) {
    return _readGateway.getPartnerHistory(query);
  }
}
