import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../tenant/tenant_lifecycle_status.dart';

/// EP-05/US-01 BR-02 / US-02 — closed (and suspended) tenants cannot be
/// selected as business context.
final class TenantMustAllowBusinessContextRule implements IBusinessRule {
  const TenantMustAllowBusinessContextRule(this.tenantStatus);

  final TenantLifecycleStatus tenantStatus;

  @override
  bool isBroken() =>
      tenantStatus == TenantLifecycleStatus.suspended ||
      tenantStatus == TenantLifecycleStatus.closed;

  @override
  String get message => switch (tenantStatus) {
        TenantLifecycleStatus.suspended =>
          'Tenant is suspended and cannot be used as business context',
        TenantLifecycleStatus.closed =>
          'Tenant is closed and cannot be used as business context',
        _ => 'Tenant status does not allow business context',
      };
}
