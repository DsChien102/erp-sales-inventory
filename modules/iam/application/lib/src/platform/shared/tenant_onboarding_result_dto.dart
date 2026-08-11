/// Result of tenant + first-owner onboarding (EP-01/US-03).
///
/// Hướng 1: for a NEW owner, the account is not created here — an activation code
/// is issued instead, so [ownerUserId]/[ownerMembershipId] are null and
/// [activationIssued] is true. For an existing owner, the membership is created
/// immediately and those ids are present.
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

  /// Present only for an existing owner (membership created immediately).
  final String? ownerMembershipId;
  final String? ownerUserId;

  /// True when a new-owner activation code was issued (no account yet).
  final bool activationIssued;
}
