import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_delivery_read_gateway.dart';
import 'get_invoice_delivery_history_query.dart';
import 'invoice_delivery_history_dto.dart';

@QueryHandlerFor(GetInvoiceDeliveryHistoryQuery)
final class GetInvoiceDeliveryHistoryQueryHandler
    implements IQueryHandler<GetInvoiceDeliveryHistoryQuery, InvoiceDeliveryHistoryDto> {
  GetInvoiceDeliveryHistoryQueryHandler({
    required IDeliveryReadGateway gateway,
  }) : _gateway = gateway;

  final IDeliveryReadGateway _gateway;

  @override
  Future<InvoiceDeliveryHistoryDto> handle(
    GetInvoiceDeliveryHistoryQuery query,
  ) {
    return _gateway.getHistory(
      tenantId: query.tenantId,
      actorId: query.actorId,
      salesOrderId: query.salesOrderId,
    );
  }
}
