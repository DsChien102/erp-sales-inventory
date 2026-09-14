import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../sales_order_cancellation_id.dart';

class SalesOrderCancellationConfirmedEvent extends DomainEventBase {
  SalesOrderCancellationConfirmedEvent({required this.cancellationId});

  final SalesOrderCancellationId cancellationId;
}
