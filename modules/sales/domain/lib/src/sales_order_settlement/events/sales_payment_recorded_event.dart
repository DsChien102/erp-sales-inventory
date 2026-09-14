import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../sales_order_settlement_id.dart';
import '../sales_payment_transaction_id.dart';

class SalesPaymentRecordedEvent extends DomainEventBase {
  SalesPaymentRecordedEvent({
    required this.settlementId,
    required this.transactionId,
  });

  final SalesOrderSettlementId settlementId;
  final SalesPaymentTransactionId transactionId;
}
