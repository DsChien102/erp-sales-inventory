/// Read-only access to the active tenant, when present.
abstract interface class ICurrentTenant {
  String? get tenantId;
}
