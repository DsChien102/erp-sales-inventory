import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'partner.dart';
import 'partner_id.dart';

/// Persistence port for the Partner aggregate.
abstract interface class IPartnerRepository {
  Future<Partner?> findById({
    required TenantId tenantId,
    required PartnerId partnerId,
  });

  Future<void> add(Partner partner);

  Future<void> save(Partner partner, {required int expectedVersion});
}
