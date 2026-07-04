/// Image payload for guided product create.
final class ProductImageInput {
  const ProductImageInput({
    required this.storageKey,
    this.url,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  final String storageKey;
  final String? url;
  final bool isPrimary;
  final int sortOrder;
}
