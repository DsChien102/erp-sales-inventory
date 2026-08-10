/// Result of resolving or provisioning the owner identity during onboarding.
final class PlatformOwnerIdentityResolutionDto {
  const PlatformOwnerIdentityResolutionDto({
    required this.ownerUserId,
    required this.isNewUser,
    required this.status,
    required this.activationDeliveryRequested,
  });

  final String ownerUserId;
  final bool isNewUser;
  final String status;
  final bool activationDeliveryRequested;
}
