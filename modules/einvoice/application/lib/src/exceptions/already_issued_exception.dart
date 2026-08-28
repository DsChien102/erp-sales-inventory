import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';

final class AlreadyIssuedException extends EInvoiceBlockedException {
  AlreadyIssuedException({required this.salesOrderId, this.electronicInvoiceId})
    : super(EInvoiceBlockedCodes.alreadyIssued);

  final String salesOrderId;
  final String? electronicInvoiceId;
}
