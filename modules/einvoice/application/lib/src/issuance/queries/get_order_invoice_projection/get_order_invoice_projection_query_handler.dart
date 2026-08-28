import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_order_invoice_projection_read_gateway.dart';
import '../../../shared/order_invoice_projection_dto.dart';
import 'get_order_invoice_projection_query.dart';

@QueryHandlerFor(GetOrderInvoiceProjectionQuery)
final class GetOrderInvoiceProjectionQueryHandler
    implements
        IQueryHandler<GetOrderInvoiceProjectionQuery, OrderInvoiceProjectionDto> {
  GetOrderInvoiceProjectionQueryHandler({
    required IOrderInvoiceProjectionReadGateway projectionGateway,
  }) : _projectionGateway = projectionGateway;

  final IOrderInvoiceProjectionReadGateway _projectionGateway;

  @override
  Future<OrderInvoiceProjectionDto> handle(
    GetOrderInvoiceProjectionQuery query,
  ) {
    return _projectionGateway.getBySalesOrder(
      tenantId: query.tenantId,
      actorId: query.actorId,
      salesOrderId: query.salesOrderId,
    );
  }
}
