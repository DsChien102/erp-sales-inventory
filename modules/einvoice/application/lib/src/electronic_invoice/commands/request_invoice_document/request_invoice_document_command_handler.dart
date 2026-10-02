import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_electronic_invoice_command_gateway.dart';
import 'request_invoice_document_command.dart';
import 'request_invoice_document_result.dart';

@CommandHandlerFor(RequestInvoiceDocumentCommand)
final class RequestInvoiceDocumentCommandHandler
    implements ICommandHandler<RequestInvoiceDocumentCommand, InvoiceDocumentRetrievalDto> {
  RequestInvoiceDocumentCommandHandler({
    required IElectronicInvoiceCommandGateway gateway,
  }) : _gateway = gateway;

  final IElectronicInvoiceCommandGateway _gateway;

  @override
  Future<InvoiceDocumentRetrievalDto> handle(
    RequestInvoiceDocumentCommand command,
  ) => _gateway.requestDocument(
    tenantId: command.tenantId,
    actorId: command.actorId,
    salesOrderId: command.salesOrderId,
    documentType: command.documentType,
  );
}
