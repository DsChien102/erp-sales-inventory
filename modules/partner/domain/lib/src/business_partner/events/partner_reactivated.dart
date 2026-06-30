import '../../ids/business_partner_id.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerReactivated extends DomainEventBase {
  PartnerReactivated({
    required this.partnerId,
    required this.tenantId,
  });

  final BusinessPartnerId partnerId;
  final TenantId tenantId;
}
