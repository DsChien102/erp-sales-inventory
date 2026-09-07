import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_electronic_invoice_read_gateway.dart';
import 'get_invoice_documents_query.dart';
import 'invoice_documents_dto.dart';

@QueryHandlerFor(GetInvoiceDocumentsQuery)
final class GetInvoiceDocumentsQueryHandler
    implements IQueryHandler<GetInvoiceDocumentsQuery, InvoiceDocumentsDto> {
  GetInvoiceDocumentsQueryHandler({
    required IElectronicInvoiceReadGateway gateway,
  }) : _gateway = gateway;

  final IElectronicInvoiceReadGateway _gateway;

  @override
  Future<InvoiceDocumentsDto> handle(GetInvoiceDocumentsQuery query) => _gateway.getDocuments(
    tenantId: query.tenantId,
    actorId: query.actorId,
    salesOrderId: query.salesOrderId,
  );
}
