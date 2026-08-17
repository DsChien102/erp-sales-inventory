import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';

final class DeliveryNotSupportedException extends EInvoiceBlockedException {
  const DeliveryNotSupportedException() : super(EInvoiceBlockedCodes.deliveryNotSupported);
}
