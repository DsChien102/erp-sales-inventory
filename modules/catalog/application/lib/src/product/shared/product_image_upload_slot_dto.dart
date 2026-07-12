/// Reserved staging slot for a product image upload.
final class ProductImageUploadSlotDto {
  const ProductImageUploadSlotDto({
    required this.slotId,
    required this.storageKey,
    required this.signedUploadUrl,
    required this.expiresAt,
  });

  final String slotId;
  final String storageKey;
  final String signedUploadUrl;
  final DateTime expiresAt;
}
