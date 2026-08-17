import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';

final class OperationInProgressException extends EInvoiceBlockedException {
  const OperationInProgressException() : super(EInvoiceBlockedCodes.operationInProgress);
}
