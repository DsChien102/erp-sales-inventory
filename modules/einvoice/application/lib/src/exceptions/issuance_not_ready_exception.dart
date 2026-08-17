import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';

final class IssuanceNotReadyException extends EInvoiceBlockedException {
  IssuanceNotReadyException({this.blockers = const []}) : super(EInvoiceBlockedCodes.issuanceNotReady);
  final List<String> blockers;
}
