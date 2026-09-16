import 'package:vet45_einvoice_domain/domain.dart';

import '../../shared/send_invoice_sheet_mode.dart';
import '../get_invoice_delivery_history/invoice_delivery_item_dto.dart';

final class SendInvoiceSheetContextDto {
  const SendInvoiceSheetContextDto({
    required this.mode,
    required this.suggestedEmail,
    required this.suggestedEmailSource,
    required this.history,
    required this.operationLocked,
    required this.displayState,
  });

  final SendInvoiceSheetMode mode;
  final String? suggestedEmail;
  final DeliveryRecipientSource? suggestedEmailSource;
  final List<InvoiceDeliveryItemDto> history;

  /// True while a delivery is `PROCESSING` for this invoice.
  /// `UNKNOWN` is historical evidence and does not lock manual resend.
  final bool operationLocked;
  final DeliveryDisplayState displayState;
}
