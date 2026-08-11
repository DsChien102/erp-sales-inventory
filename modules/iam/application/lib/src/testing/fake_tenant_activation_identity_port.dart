import '../tenant/shared/tenant_activation_identity_snapshot.dart';
import '../ports/i_tenant_activation_identity_port.dart';
import '../shared/iam_blocked_codes.dart';
import '../shared/iam_blocked_exception.dart';
import 'fake_iam_scenario.dart';

/// Fake activation snapshot provider for readiness tests (§S11).
final class FakeTenantActivationIdentityPort
    implements ITenantActivationIdentityPort {
  FakeTenantActivationIdentityPort({
    this.scenario = FakeIamScenario.readinessWarningOnly,
  });

  final FakeIamScenario scenario;

  @override
  Future<TenantActivationIdentitySnapshot> getActivationSnapshot({
    required String tenantId,
    required String ownerUserId,
  }) async {
    if (scenario == FakeIamScenario.readinessBlocked) {
      return TenantActivationIdentitySnapshot(
        userId: ownerUserId,
        identityStatus: 'inactive',
        emailVerified: false,
        platformBlockerCodes: const ['PLATFORM_BLOCKER_PRESENT'],
        snapshotVersion: 'snap-1',
      );
    }
    return TenantActivationIdentitySnapshot(
      userId: ownerUserId,
      identityStatus: 'active',
      emailVerified: true,
      platformBlockerCodes: const [],
      snapshotVersion: 'snap-1',
    );
  }
}

/// Unavailable activation identity port for unit tests.
final class UnavailableTenantActivationIdentityPortFake
    implements ITenantActivationIdentityPort {
  @override
  Future<TenantActivationIdentitySnapshot> getActivationSnapshot({
    required String tenantId,
    required String ownerUserId,
  }) {
    throw const IamBlockedException(IamBlockedCodes.systemError);
  }
}
