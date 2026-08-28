import '../shared/order_invoice_projection_dto.dart';

abstract interface class IOrderInvoiceProjectionReadGateway {
  Future<OrderInvoiceProjectionDto> getBySalesOrder({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });
}
