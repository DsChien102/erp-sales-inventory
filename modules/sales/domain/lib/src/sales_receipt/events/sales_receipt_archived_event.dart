import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../sales_receipt_id.dart';

class SalesReceiptArchivedEvent extends DomainEventBase {
  SalesReceiptArchivedEvent({required this.receiptId});

  final SalesReceiptId receiptId;
}
