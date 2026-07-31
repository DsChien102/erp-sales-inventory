/// IAM-owned permission codes for RBAC metadata, manifests, and seeds.
abstract final class IamPermissions {
  static const membersRead = 'iam.members.read';
  static const membersAssignRole = 'iam.members.assign_role';

  // Theme-1 product permission codes (S10–S14).
  static const memberView = 'tenant.member.view';
  static const memberInvite = 'tenant.member.invite';
  static const memberStatusUpdate = 'tenant.member.status.update';
  static const memberRemove = 'tenant.member.remove';
  static const tenantView = 'tenant.view';
  static const tenantProfileUpdate = 'tenant.profile.update';
  static const tenantLegalProfileUpdate = 'tenant.legal_profile.update';
  static const tenantReadinessView = 'tenant.readiness.view';
  static const tenantActivate = 'tenant.activate';
  static const tenantAuditView = 'tenant.audit.view';
}
