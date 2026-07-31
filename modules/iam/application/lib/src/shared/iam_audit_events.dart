/// Stable IAM audit event codes (§Task 7 minimum set).
///
/// These mirror the `event_code` values written by IAM mutation RPCs into
/// `iam.audit_logs`. Kept as a single source of truth so presentation and
/// tests can map events without hardcoding strings.
abstract final class IamAuditEvents {
  static const membershipDeactivated = 'iam.membership.deactivated';
  static const membershipReactivated = 'iam.membership.reactivated';
  static const membershipRemoved = 'iam.membership.removed';
  static const tenantProfileUpdated = 'iam.tenant.profile_updated';
  static const tenantLegalProfileUpdated = 'iam.tenant.legal_profile_updated';
  static const tenantActivated = 'iam.tenant.activated';
  static const tenantSuspended = 'iam.tenant.suspended';
  static const tenantRestored = 'iam.tenant.restored';
  static const tenantOwnershipTransferred = 'iam.tenant.ownership_transferred';
  static const accountProfileUpdated = 'iam.account.profile_updated';
  static const accountPasswordResetCompleted =
      'iam.account.password_reset_completed';
  static const accountSignedOut = 'iam.account.signed_out';

  /// The full minimum event set that must be produced by IAM mutations.
  static const List<String> all = [
    membershipDeactivated,
    membershipReactivated,
    membershipRemoved,
    tenantProfileUpdated,
    tenantLegalProfileUpdated,
    tenantActivated,
    tenantSuspended,
    tenantRestored,
    tenantOwnershipTransferred,
    accountProfileUpdated,
    accountPasswordResetCompleted,
    accountSignedOut,
  ];
}
