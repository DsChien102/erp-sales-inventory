import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_reconciliation_gateway.dart';
import 'get_issuance_attempt_status_query.dart';
import 'issuance_attempt_status_dto.dart';

@QueryHandlerFor(GetIssuanceAttemptStatusQuery)
final class GetIssuanceAttemptStatusQueryHandler
    implements IQueryHandler<GetIssuanceAttemptStatusQuery, IssuanceAttemptStatusDto> {
  GetIssuanceAttemptStatusQueryHandler({
    required IIssuanceReconciliationGateway gateway,
  }) : _gateway = gateway;

  final IIssuanceReconciliationGateway _gateway;

  @override
  Future<IssuanceAttemptStatusDto> handle(GetIssuanceAttemptStatusQuery query) {
    return _gateway.getAttemptStatus(
      tenantId: query.tenantId,
      actorId: query.actorId,
      salesOrderId: query.salesOrderId,
    );
  }
}
