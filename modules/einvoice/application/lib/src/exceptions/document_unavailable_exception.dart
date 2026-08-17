import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';

final class DocumentUnavailableException extends EInvoiceBlockedException {
  const DocumentUnavailableException() : super(EInvoiceBlockedCodes.documentUnavailable);
}
