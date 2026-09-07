import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_delivery_read_gateway.dart';
import 'get_send_invoice_sheet_context_query.dart';
import 'send_invoice_sheet_context_dto.dart';

@QueryHandlerFor(GetSendInvoiceSheetContextQuery)
final class GetSendInvoiceSheetContextQueryHandler
    implements IQueryHandler<GetSendInvoiceSheetContextQuery, SendInvoiceSheetContextDto> {
  GetSendInvoiceSheetContextQueryHandler({
    required IDeliveryReadGateway gateway,
  }) : _gateway = gateway;

  final IDeliveryReadGateway _gateway;

  @override
  Future<SendInvoiceSheetContextDto> handle(
    GetSendInvoiceSheetContextQuery query,
  ) {
    return _gateway.getSendSheetContext(
      tenantId: query.tenantId,
      actorId: query.actorId,
      salesOrderId: query.salesOrderId,
    );
  }
}
