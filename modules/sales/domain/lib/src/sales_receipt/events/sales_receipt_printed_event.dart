import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../sales_receipt_id.dart';

class SalesReceiptPrintedEvent extends DomainEventBase {
  SalesReceiptPrintedEvent({required this.receiptId});

  final SalesReceiptId receiptId;
}
