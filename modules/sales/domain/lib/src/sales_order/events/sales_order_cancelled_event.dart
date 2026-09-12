import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../sales_order_id.dart';

class SalesOrderCancelledEvent extends DomainEventBase {
  SalesOrderCancelledEvent({required this.orderId});

  final SalesOrderId orderId;
}
