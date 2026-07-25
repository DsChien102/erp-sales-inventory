final class ProductUnitRefDto {
  const ProductUnitRefDto({
    required this.productId,
    required this.productName,
    required this.productUnitId,
    required this.unitName,
    required this.sellableStatus,
    this.productReferenceId,
    this.sku,
  });

  final String productId;
  final String productName;
  final String productUnitId;
  final String unitName;
  final String sellableStatus;
  final String? productReferenceId;
  final String? sku;
}
