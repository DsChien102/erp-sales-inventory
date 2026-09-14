import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../sales_order_settlement_id.dart';

class SalesReceivableRequiredEvent extends DomainEventBase {
  SalesReceivableRequiredEvent({required this.settlementId});

  final SalesOrderSettlementId settlementId;
}
