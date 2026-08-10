import '../tenant/shared/tenant_activation_result_dto.dart';

/// Command port for Tenant activation (§S11).
abstract interface class ITenantActivationCommandGateway {
  Future<TenantActivationResultDto> activate({
    required String tenantId,
    required int expectedVersion,
    required String idempotencyKey,
  });
}
