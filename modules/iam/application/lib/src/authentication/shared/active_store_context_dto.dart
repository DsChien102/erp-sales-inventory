/// Authoritative active-store identity resolved for the signed-in principal.
final class ActiveStoreContextDto {
  const ActiveStoreContextDto({
    required this.userId,
    required this.tenantId,
    required this.storeId,
    required this.storeCode,
    required this.displayName,
  });

  final String userId;
  final String tenantId;
  final String storeId;
  final String storeCode;
  final String displayName;
}
