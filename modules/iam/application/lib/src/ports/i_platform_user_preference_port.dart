/// Platform User Preference port — LastSelectedTenant (EP-05/US-03).
///
/// Preference is **not** an access grant. Callers must re-validate tenant
/// access via [IIamAccessGateway.getValidatedTenantContext] before resolving
/// business context.
abstract interface class IPlatformUserPreferencePort {
  Future<String?> getLastSelectedTenantId();

  Future<void> setLastSelectedTenantId(String? tenantId);
}
