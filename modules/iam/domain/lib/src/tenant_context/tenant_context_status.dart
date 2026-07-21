/// Runtime TenantContext lifecycle (D-04) — not a persisted aggregate.
enum TenantContextStatus {
  /// No resolved business tenant (selector / bootstrap miss).
  none,

  /// Validated active membership + allowable tenant status.
  valid,

  /// Previously valid context no longer usable (US-04).
  invalidated,
}
