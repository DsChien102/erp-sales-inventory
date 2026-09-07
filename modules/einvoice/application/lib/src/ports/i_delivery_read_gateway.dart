import '../delivery/queries/get_invoice_delivery_history/invoice_delivery_history_dto.dart';
import '../delivery/queries/get_send_invoice_sheet_context/send_invoice_sheet_context_dto.dart';

abstract interface class IDeliveryReadGateway {
  Future<SendInvoiceSheetContextDto> getSendSheetContext({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });

  Future<InvoiceDeliveryHistoryDto> getHistory({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });
}
