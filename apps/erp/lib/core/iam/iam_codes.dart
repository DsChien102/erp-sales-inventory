/// Mã lỗi nghiệp vụ ổn định mà UI map sang thông báo (khớp mã RPC / `blocked_error_code`).
///
/// Chỉ giữ các mã app đang dùng; danh mục đầy đủ ở TH-01 (docs/02-yeu-cau).
abstract final class IamBlockedCodes {
  static const resourceNotFound = 'RESOURCE_NOT_FOUND';
  static const validationError = 'VALIDATION_ERROR';
  static const permissionDenied = 'PERMISSION_DENIED';
  static const stateChanged = 'STATE_CHANGED';
  static const lastOwnerProtected = 'LAST_OWNER_PROTECTED';
  static const membershipInactive = 'MEMBERSHIP_INACTIVE';
  static const noActiveMembership = 'NO_ACTIVE_MEMBERSHIP';
  static const contextInvalid = 'CONTEXT_INVALID';
  static const membershipRemoved = 'MEMBERSHIP_REMOVED';
  static const duplicateMembership = 'DUPLICATE_MEMBERSHIP';
  static const roleNotAssignable = 'ROLE_NOT_ASSIGNABLE';
  static const ownerIdentityUnavailable = 'OWNER_IDENTITY_UNAVAILABLE';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const tenantStateInvalid = 'TENANT_STATE_INVALID';
  static const systemError = 'SYSTEM_ERROR';
  static const authenticationRequired = 'AUTHENTICATION_REQUIRED';
  static const sessionExpired = 'SESSION_EXPIRED';
  static const resetRateLimited = 'RESET_RATE_LIMITED';
  static const resetCodeInvalid = 'RESET_CODE_INVALID';
  static const resetCodeExpired = 'RESET_CODE_EXPIRED';
  static const resetCodeAttemptsExceeded = 'RESET_CODE_ATTEMPTS_EXCEEDED';
  static const passwordPolicyViolation = 'PASSWORD_POLICY_VIOLATION';
  static const invitationTokenInvalid = 'INVITATION_TOKEN_INVALID';
  static const invitationExpired = 'INVITATION_EXPIRED';
  static const invitationRevoked = 'INVITATION_REVOKED';
  static const invitationAlreadyUsed = 'INVITATION_ALREADY_USED';
  static const invitationEmailMismatch = 'INVITATION_EMAIL_MISMATCH';
  static const invitationPendingExists = 'INVITATION_PENDING_EXISTS';
  static const platformUserAlreadyExists = 'PLATFORM_USER_ALREADY_EXISTS';
  static const stepUpAuthRequired = 'STEP_UP_AUTH_REQUIRED';
  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const identityEmailNotVerified = 'IDENTITY_EMAIL_NOT_VERIFIED';
}

/// Mã quyền sản phẩm của TH-01 mà router / UI kiểm tra.
abstract final class IamPermissions {
  static const memberView = 'tenant.member.view';
  static const memberInvite = 'tenant.member.invite';
  static const memberStatusUpdate = 'tenant.member.status.update';
  static const memberRemove = 'tenant.member.remove';
  static const tenantView = 'tenant.view';
  static const tenantProfileUpdate = 'tenant.profile.update';
  static const tenantLegalProfileUpdate = 'tenant.legal_profile.update';
  static const tenantAuditView = 'tenant.audit.view';
}

/// Mã sự kiện audit (`event_code` trong `iam.audit_logs`).
abstract final class IamAuditEvents {
  static const membershipDeactivated = 'iam.membership.deactivated';
  static const membershipReactivated = 'iam.membership.reactivated';
  static const membershipRemoved = 'iam.membership.removed';
  static const memberRoleAssigned = 'iam.tenant.member_role_assigned';

  static const tenantProfileUpdated = 'iam.tenant.profile_updated';
  static const tenantLegalProfileUpdated = 'iam.tenant.legal_profile_updated';
  static const tenantActivated = 'iam.tenant.activated';
  static const tenantOwnerActivated = 'iam.tenant.owner_activated';

  static const invitationCreated = 'iam.tenant.invitation_created';
  static const invitationResent = 'iam.tenant.invitation_resent';
  static const invitationRevoked = 'iam.tenant.invitation_revoked';
  static const invitationAccepted = 'iam.tenant.invitation_accepted';

  static const accountProfileUpdated = 'iam.account.profile_updated';
  static const userProfileUpdated = 'iam.user.profile_updated';
  static const accountPasswordResetCompleted = 'iam.account.password_reset_completed';
  static const accountSignedOut = 'iam.account.signed_out';

  /// Toàn bộ mã mà các RPC ghi của IAM có thể tạo ra.
  static const List<String> all = [
    membershipDeactivated,
    membershipReactivated,
    membershipRemoved,
    memberRoleAssigned,
    tenantProfileUpdated,
    tenantLegalProfileUpdated,
    tenantActivated,
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
