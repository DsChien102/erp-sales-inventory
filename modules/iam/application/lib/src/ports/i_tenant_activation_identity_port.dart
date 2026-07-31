import '../dto/tenant_activation_identity_snapshot.dart';

/// Platform Identity activation snapshot provider (§S11).
abstract interface class ITenantActivationIdentityPort {
  Future<TenantActivationIdentitySnapshot> getActivationSnapshot({
    required String tenantId,
    required String ownerUserId,
  });
}
