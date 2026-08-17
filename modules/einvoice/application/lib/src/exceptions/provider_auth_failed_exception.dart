import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';

final class ProviderAuthFailedException extends EInvoiceBlockedException {
  const ProviderAuthFailedException() : super(EInvoiceBlockedCodes.providerAuthFailed);
}
