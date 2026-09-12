import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../return_exchange_order_id.dart';

class ReturnExchangeValuedEvent extends DomainEventBase {
  ReturnExchangeValuedEvent({required this.returnExchangeId});

  final ReturnExchangeOrderId returnExchangeId;
}
