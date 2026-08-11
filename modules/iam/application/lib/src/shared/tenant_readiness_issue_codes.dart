/// Stable readiness issue codes (§S11).
abstract final class TenantReadinessIssueCodes {
  // Blockers
  static const displayNameMissing = 'TENANT_DISPLAY_NAME_MISSING';
  static const contactEmailMissingOrInvalid =
      'TENANT_CONTACT_EMAIL_MISSING_OR_INVALID';
  static const contactPhoneMissingOrInvalid =
      'TENANT_CONTACT_PHONE_MISSING_OR_INVALID';
  static const contactAddressMissing = 'TENANT_CONTACT_ADDRESS_MISSING';
  static const ownerMembershipInvalid = 'OWNER_MEMBERSHIP_INVALID';
  static const ownerRoleInvalid = 'OWNER_ROLE_INVALID';
  static const ownerIdentityInactive = 'OWNER_IDENTITY_INACTIVE';
  static const ownerIdentityUnavailable = 'OWNER_IDENTITY_UNAVAILABLE';
  static const ownerEmailUnverified = 'OWNER_EMAIL_UNVERIFIED';
  static const platformBlockerPresent = 'PLATFORM_BLOCKER_PRESENT';

  // Warnings
  static const legalProfileMissing = 'LEGAL_PROFILE_MISSING';
  static const duplicateTaxCode = 'DUPLICATE_TAX_CODE';
}
