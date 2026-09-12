import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../sales_order_settlement_id.dart';

class SalesOrderSettlementInitializedEvent extends DomainEventBase {
  SalesOrderSettlementInitializedEvent({required this.settlementId});

  final SalesOrderSettlementId settlementId;
}
