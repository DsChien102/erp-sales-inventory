/// Ensures the current principal may access the requested tenant.
abstract interface class ITenantAccessChecker {
  Future<void> ensureAccess(String tenantId);
}
