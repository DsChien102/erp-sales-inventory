import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_partner_read_gateway.dart';
import 'get_partner_action_logs_query.dart';
import 'partner_action_log_result_dto.dart';

@QueryHandlerFor(GetPartnerActionLogsQuery)
final class GetPartnerActionLogsQueryHandler
    implements
        IQueryHandler<GetPartnerActionLogsQuery, PartnerActionLogResultDto> {
  GetPartnerActionLogsQueryHandler({required IPartnerReadGateway readGateway})
    : _readGateway = readGateway;

  final IPartnerReadGateway _readGateway;

  @override
  Future<PartnerActionLogResultDto> handle(GetPartnerActionLogsQuery query) {
    return _readGateway.getPartnerActionLogs(query);
  }
}
