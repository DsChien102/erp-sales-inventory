/// Result of tenant + first-owner onboarding (EP-01/US-03).
///
/// Trước khi accept Invitation, [ownerMembershipId] là null. [ownerUserId] là
/// null với người được mời mới hoặc là ID Auth user đã có; onboarding không
/// tạo profile hay Membership cho người được mời.
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

  /// Owner membership after accept; null while Invitation is still pending.
  final String? ownerMembershipId;
  final String? ownerUserId;

  /// True when an owner invitation / activation email was queued.
  final bool activationIssued;
}
