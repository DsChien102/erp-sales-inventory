import '../dto/tenant_dto.dart';

/// Read port for Tenant profile + Legal Profile (§S12).
abstract interface class ITenantProfileReadGateway {
  Future<TenantDto?> getTenant({required String tenantId});
}
