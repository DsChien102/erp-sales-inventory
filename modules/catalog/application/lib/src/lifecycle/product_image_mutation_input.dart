/// Image payload for replacing the current visible product gallery.
final class ProductImageMutationInput {
  const ProductImageMutationInput({
    this.imageId,
    required this.storageKey,
    this.slotId,
    this.url,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  final String? imageId;
  final String storageKey;
  final String? slotId;
  final String? url;
  final bool isPrimary;
  final int sortOrder;
}
