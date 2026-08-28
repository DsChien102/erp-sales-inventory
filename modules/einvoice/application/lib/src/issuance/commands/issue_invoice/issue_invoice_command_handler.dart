import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_command_gateway.dart';
import 'issue_invoice_command.dart';
import 'issue_invoice_result.dart';
import 'issue_invoice_start_request.dart';

@CommandHandlerFor(IssueInvoiceCommand)
final class IssueInvoiceCommandHandler
    implements ICommandHandler<IssueInvoiceCommand, IssueInvoiceResultDto> {
  IssueInvoiceCommandHandler({required IIssuanceCommandGateway gateway}) : _gateway = gateway;

  final IIssuanceCommandGateway _gateway;

  @override
  Future<IssueInvoiceResultDto> handle(IssueInvoiceCommand command) {
    return _gateway.issueInvoice(
      IssueInvoiceStartRequest(
        tenantId: command.tenantId,
        actorId: command.actorId,
        salesOrderId: command.salesOrderId,
        sourceVersion: command.sourceVersion,
        idempotencyKey: command.idempotencyKey,
        acknowledgeWarnings: command.acknowledgeWarnings ?? false,
      ),
    );
  }
}
