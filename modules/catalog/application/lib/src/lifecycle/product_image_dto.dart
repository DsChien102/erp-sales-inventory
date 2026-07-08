/// Product image projection returned by product maintenance commands.
final class ProductImageDto {
  const ProductImageDto({
    required this.imageId,
    required this.storageKey,
    this.url,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  final String imageId;
  final String storageKey;
  final String? url;
  final bool isPrimary;
  final int sortOrder;
}
