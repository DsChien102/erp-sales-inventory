import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';

final class ProviderUnavailableException extends EInvoiceBlockedException {
  const ProviderUnavailableException() : super(EInvoiceBlockedCodes.providerUnavailable);
}
