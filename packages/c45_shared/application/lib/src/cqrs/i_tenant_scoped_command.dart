/// Marker for commands that carry an explicit tenant scope.
abstract interface class ITenantScopedCommand {
  String get tenantId;
}
