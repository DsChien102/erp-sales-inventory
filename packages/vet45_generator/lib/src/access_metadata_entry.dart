final class AccessMetadataEntry {
  const AccessMetadataEntry({
    required this.typeName,
    required this.permission,
    required this.isPublic,
    required this.requiresTenant,
    required this.idempotencyKeyField,
  });

  final String typeName;
  final String? permission;
  final bool isPublic;
  final bool requiresTenant;
  final String? idempotencyKeyField;
}
