import '../../ids/business_partner_id.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerDeactivated extends DomainEventBase {
  PartnerDeactivated({
    required this.partnerId,
    required this.tenantId,
    this.statusNote,
  });

  final BusinessPartnerId partnerId;
  final TenantId tenantId;
  final String? statusNote;
}
