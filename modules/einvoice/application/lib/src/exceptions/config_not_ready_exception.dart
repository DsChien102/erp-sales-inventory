import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';

final class ConfigNotReadyException extends EInvoiceBlockedException {
  ConfigNotReadyException({this.blockers = const []}) : super(EInvoiceBlockedCodes.configNotReady);
  final List<String> blockers;
}
