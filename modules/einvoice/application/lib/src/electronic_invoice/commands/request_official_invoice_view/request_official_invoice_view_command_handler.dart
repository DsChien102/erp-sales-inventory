import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_electronic_invoice_command_gateway.dart';
import 'request_official_invoice_view_command.dart';
import 'request_official_invoice_view_result.dart';

@CommandHandlerFor(RequestOfficialInvoiceViewCommand)
final class RequestOfficialInvoiceViewCommandHandler
    implements ICommandHandler<RequestOfficialInvoiceViewCommand, OfficialInvoiceViewDto> {
  RequestOfficialInvoiceViewCommandHandler({
    required IElectronicInvoiceCommandGateway gateway,
  }) : _gateway = gateway;

  final IElectronicInvoiceCommandGateway _gateway;

  @override
  Future<OfficialInvoiceViewDto> handle(
    RequestOfficialInvoiceViewCommand command,
  ) => _gateway.requestOfficialView(
    tenantId: command.tenantId,
    actorId: command.actorId,
    salesOrderId: command.salesOrderId,
  );
}
