import '../../ids/business_partner_id.dart';
import '../business_partner.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

abstract interface class IBusinessPartnerRepository {
  Future<BusinessPartner?> findById({
    required BusinessPartnerId id,
    required TenantId tenantId,
  });

  Future<void> save(BusinessPartner partner);
}
