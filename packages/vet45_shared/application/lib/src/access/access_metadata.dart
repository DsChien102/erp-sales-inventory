/// Access metadata for command/query message types (codegen-populated).
final class AccessMetadata {
  const AccessMetadata({
    this.permission,
    this.isPublic = false,
    this.requiresTenant = false,
    this.idempotencyKeyField,
  });

  final String? permission;
  final bool isPublic;
  final bool requiresTenant;
  final String? idempotencyKeyField;

  bool get requiresAuthentication => !isPublic && permission != null;
}

/// Lookup access metadata by message runtime type.
abstract interface class IAccessMetadataRegistry {
  AccessMetadata? forType(Type messageType);
}
