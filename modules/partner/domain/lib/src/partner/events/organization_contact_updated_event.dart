import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../partner_id.dart';

class OrganizationContactUpdatedEvent extends DomainEventBase {
  OrganizationContactUpdatedEvent({
    required this.organizationPartnerId,
    required this.personPartnerId,
  });

  final PartnerId organizationPartnerId;
  final PartnerId personPartnerId;
}
