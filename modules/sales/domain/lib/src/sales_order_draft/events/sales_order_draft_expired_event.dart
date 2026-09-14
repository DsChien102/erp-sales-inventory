import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../sales_order_draft_id.dart';

class SalesOrderDraftExpiredEvent extends DomainEventBase {
  SalesOrderDraftExpiredEvent({required this.draftId});

  final SalesOrderDraftId draftId;
}
