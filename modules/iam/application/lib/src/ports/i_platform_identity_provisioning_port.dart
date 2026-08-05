import '../dto/onboarding_owner_input.dart';
import '../dto/platform_owner_identity_resolution_dto.dart';

/// Privileged Platform Identity boundary used by onboarding.
abstract interface class IPlatformIdentityProvisioningPort {
  Future<PlatformOwnerIdentityResolutionDto> resolveOrCreateOwnerForOnboarding({
    required OnboardingOwnerInput owner,
    required String idempotencyKey,
    String? correlationId,
  });
}
