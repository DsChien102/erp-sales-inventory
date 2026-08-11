import 'package:vet45_iam_application/application.dart';

/// Fail-fast adapter until Platform Identity activation contract ships (§S11).
final class UnavailableTenantActivationIdentityPort
    implements ITenantActivationIdentityPort {
  @override
  Future<TenantActivationIdentitySnapshot> getActivationSnapshot({
    required String tenantId,
    required String ownerUserId,
  }) {
    throw const IamBlockedException(IamBlockedCodes.systemError);
  }
}
