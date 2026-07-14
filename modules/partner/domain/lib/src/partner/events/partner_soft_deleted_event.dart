import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../partner_id.dart';

class PartnerSoftDeletedEvent extends DomainEventBase {
  PartnerSoftDeletedEvent({required this.partnerId});

  final PartnerId partnerId;
}
