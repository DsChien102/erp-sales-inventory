/// Requires a permission code before the annotated command/query runs.
///
/// Apply to command or query classes, not handlers.
class RequiresPermission {
  const RequiresPermission(this.code);

  final String code;
}

/// Allows anonymous access to the annotated command/query.
class PublicAccess {
  const PublicAccess();
}

/// Requires an active tenant context for the annotated command/query.
class RequiresTenant {
  const RequiresTenant();
}

/// Marks a command as idempotent; [keyField] names the payload field used as idempotency key.
class Idempotent {
  const Idempotent({this.keyField});

  final String? keyField;
}
