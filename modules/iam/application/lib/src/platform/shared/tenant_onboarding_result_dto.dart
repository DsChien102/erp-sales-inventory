/// Result of tenant + first-owner onboarding (EP-01/US-03).
///
/// Hybrid: onboarding always creates Owner Membership immediately (new and
/// existing owners) and issues an activation invitation. [ownerMembershipId]
/// / [ownerUserId] are set when the RPC returns them; [activationIssued] is
/// true when an activation invitation was queued.
final class TenantOnboardingResultDto {
  const TenantOnboardingResultDto({
    required this.tenantId,
    required this.tenantStatus,
    required this.correlationId,
    required this.isNewUser,
    this.ownerMembershipId,
    this.ownerUserId,
    this.activationIssued = false,
  });

  final String tenantId;

  /// Expected interim value: `provisioning`.
  final String tenantStatus;
  final String correlationId;
  final bool isNewUser;

  /// Owner membership created at onboarding (hybrid).
  final String? ownerMembershipId;
  final String? ownerUserId;

  /// True when an activation invitation / code was queued.
  final bool activationIssued;
}
