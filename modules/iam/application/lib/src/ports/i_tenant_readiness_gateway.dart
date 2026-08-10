import '../tenant/shared/tenant_readiness_dto.dart';

/// Read port for derived Tenant readiness (§S11).
abstract interface class ITenantReadinessGateway {
  Future<TenantReadinessDto> getReadiness({required String tenantId});
}
