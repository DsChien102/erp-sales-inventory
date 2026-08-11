/// Stable blocked codes for IAM presentation mapping.
///
/// Canonical catalog: `docs/themes/TH-01-organization-users/APPENDICES.md` §6.4.
abstract final class IamBlockedCodes {
  static const resourceNotFound = 'RESOURCE_NOT_FOUND';
  static const validationError = 'VALIDATION_ERROR';
  static const permissionDenied = 'PERMISSION_DENIED';
  static const stateChanged = 'STATE_CHANGED';
  static const lastOwnerProtected = 'LAST_OWNER_PROTECTED';
  static const membershipInactive = 'MEMBERSHIP_INACTIVE';
  static const membershipRemoved = 'MEMBERSHIP_REMOVED';
  static const duplicateMembership = 'DUPLICATE_MEMBERSHIP';
  static const roleNotAssignable = 'ROLE_NOT_ASSIGNABLE';
  static const readinessBlocked = 'READINESS_BLOCKED';
  static const ownerIdentityUnavailable = 'OWNER_IDENTITY_UNAVAILABLE';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const tenantStateInvalid = 'TENANT_STATE_INVALID';
  static const tenantSuspended = 'TENANT_SUSPENDED';
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
  static const ownerTargetInvalid = 'OWNER_TARGET_INVALID';
  static const platformPermissionDenied = 'PLATFORM_PERMISSION_DENIED';
}
