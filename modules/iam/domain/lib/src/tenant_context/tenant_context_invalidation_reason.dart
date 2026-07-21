/// Why a TenantContext became [TenantContextStatus.invalidated] (US-04).
enum TenantContextInvalidationReason {
  membershipRemoved,
  membershipInactive,
  tenantSuspended,
  tenantClosed,
  accessDenied,
}
