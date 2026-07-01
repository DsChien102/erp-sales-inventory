import '../../ids/business_partner_id.dart';
import '../../shared/entity_type.dart';
import '../../shared/partner_role.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerRegistered extends DomainEventBase {
  PartnerRegistered({
    required this.partnerId,
    required this.tenantId,
    required this.entityType,
    required this.roles,
    required this.displayName,
  });

  final BusinessPartnerId partnerId;
  final TenantId tenantId;
  final EntityType entityType;
  final Set<PartnerRole> roles;
  final String displayName;
}
