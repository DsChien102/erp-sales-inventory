import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../partner_id.dart';

class OrganizationContactRemovedEvent extends DomainEventBase {
  OrganizationContactRemovedEvent({
    required this.organizationPartnerId,
    required this.personPartnerId,
  });

  final PartnerId organizationPartnerId;
  final PartnerId personPartnerId;
}
