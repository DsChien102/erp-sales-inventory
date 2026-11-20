final class ProductSnapshotDto {
  const ProductSnapshotDto({
    required this.productId,
    required this.sku,
    required this.displayName,
  });

  final String productId;
  final String? sku;
  final String displayName;
}
