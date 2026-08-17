import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';

final class ProviderNotConnectedException extends EInvoiceBlockedException {
  const ProviderNotConnectedException() : super(EInvoiceBlockedCodes.providerNotConnected);
}
