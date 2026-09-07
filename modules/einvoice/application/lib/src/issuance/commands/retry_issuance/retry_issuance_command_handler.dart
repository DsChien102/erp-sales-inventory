import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_command_gateway.dart';
import '../issue_invoice/issue_invoice_result.dart';
import 'retry_issuance_command.dart';
import 'retry_issuance_start_request.dart';

@CommandHandlerFor(RetryIssuanceCommand)
final class RetryIssuanceCommandHandler
    implements ICommandHandler<RetryIssuanceCommand, IssueInvoiceResultDto> {
  RetryIssuanceCommandHandler({
    required IIssuanceCommandGateway gateway,
  }) : _gateway = gateway;

  final IIssuanceCommandGateway _gateway;

  @override
  Future<IssueInvoiceResultDto> handle(RetryIssuanceCommand command) {
    return _gateway.retryIssuance(
      RetryIssuanceStartRequest(
        tenantId: command.tenantId,
        actorId: command.actorId,
        salesOrderId: command.salesOrderId,
        expectedOrderVersion: command.expectedOrderVersion,
        idempotencyKey: command.idempotencyKey,
        acknowledgeWarnings: command.acknowledgeWarnings ?? false,
      ),
    );
  }
}
