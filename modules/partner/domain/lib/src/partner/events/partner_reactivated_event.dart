import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../partner_id.dart';

class PartnerReactivatedEvent extends DomainEventBase {
  PartnerReactivatedEvent({required this.partnerId});

  final PartnerId partnerId;
}
