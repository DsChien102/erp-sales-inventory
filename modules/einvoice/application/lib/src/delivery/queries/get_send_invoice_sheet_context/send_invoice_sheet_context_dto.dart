import '../../shared/send_invoice_sheet_mode.dart';
import '../get_invoice_delivery_history/invoice_delivery_item_dto.dart';

final class SendInvoiceSheetContextDto {
  const SendInvoiceSheetContextDto({
    required this.mode,
    this.suggestedEmail,
    required this.history,
  });

  final SendInvoiceSheetMode mode;
  final String? suggestedEmail;
  final List<InvoiceDeliveryItemDto> history;
}
