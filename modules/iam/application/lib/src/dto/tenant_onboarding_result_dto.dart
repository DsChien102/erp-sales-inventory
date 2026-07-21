/// Result of atomic tenant + first-owner onboarding (EP-01/US-03).
final class TenantOnboardingResultDto {
  const TenantOnboardingResultDto({
    required this.tenantId,
    required this.ownerMembershipId,
    required this.ownerUserId,
    required this.tenantStatus,
    required this.correlationId,
    required this.isNewUser,
  });

  final String tenantId;
  final String ownerMembershipId;
  final String ownerUserId;

  /// Expected interim value: `provisioning`.
  final String tenantStatus;
  final String correlationId;
  final bool isNewUser;
}
