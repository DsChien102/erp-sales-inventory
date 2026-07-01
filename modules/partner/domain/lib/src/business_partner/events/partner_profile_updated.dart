import '../../ids/business_partner_id.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerProfileUpdated extends DomainEventBase {
  PartnerProfileUpdated({
    required this.partnerId,
    required this.tenantId,
    required this.displayName,
  });

  final BusinessPartnerId partnerId;
  final TenantId tenantId;
  final String displayName;
}
