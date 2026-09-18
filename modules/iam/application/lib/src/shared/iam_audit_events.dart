/// Stable IAM audit event codes (§S13).
///
/// These mirror the `event_code` values written by IAM mutation RPCs into
/// `iam.audit_logs`. Kept as a single source of truth so presentation and
/// tests can map events without hardcoding strings.
abstract final class IamAuditEvents {
  static const membershipDeactivated = 'iam.membership.deactivated';
  static const membershipReactivated = 'iam.membership.reactivated';
  static const membershipRemoved = 'iam.membership.removed';
  static const memberRoleAssigned = 'iam.tenant.member_role_assigned';

  static const tenantProfileUpdated = 'iam.tenant.profile_updated';
  static const tenantLegalProfileUpdated = 'iam.tenant.legal_profile_updated';
  static const tenantActivated = 'iam.tenant.activated';
  static const tenantSuspended = 'iam.tenant.suspended';
  static const tenantRestored = 'iam.tenant.restored';
  static const tenantClosed = 'iam.tenant.closed';
  static const tenantOwnershipTransferred = 'iam.tenant.ownership_transferred';
  static const tenantOwnerActivated = 'iam.tenant.owner_activated';

  static const invitationCreated = 'iam.tenant.invitation_created';
  static const invitationResent = 'iam.tenant.invitation_resent';
  static const invitationRevoked = 'iam.tenant.invitation_revoked';
  static const invitationAccepted = 'iam.tenant.invitation_accepted';

  static const accountProfileUpdated = 'iam.account.profile_updated';
  static const userProfileUpdated = 'iam.user.profile_updated';
  static const accountPasswordResetCompleted = 'iam.account.password_reset_completed';
  static const accountSignedOut = 'iam.account.signed_out';

  /// The full event set that can be produced by IAM mutations.
  static const List<String> all = [
    membershipDeactivated,
    membershipReactivated,
    membershipRemoved,
    memberRoleAssigned,
    tenantProfileUpdated,
    tenantLegalProfileUpdated,
    tenantActivated,
    tenantSuspended,
    tenantRestored,
    tenantClosed,
    tenantOwnershipTransferred,
    tenantOwnerActivated,
    invitationCreated,
    invitationResent,
    invitationRevoked,
    invitationAccepted,
    accountProfileUpdated,
    userProfileUpdated,
    accountPasswordResetCompleted,
    accountSignedOut,
  ];
}
