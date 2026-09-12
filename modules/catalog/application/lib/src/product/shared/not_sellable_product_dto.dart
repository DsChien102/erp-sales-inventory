/// Identity of a product that exists but cannot be sold right now.
///
/// Carries just enough to name the product in a message, so the caller does not
/// need a second lookup to explain why the line is blocked.
final class NotSellableProductDto {
  const NotSellableProductDto({
    required this.productId,
    this.sku,
    this.displayName,
    this.blockReason,
  });

  final String productId;
  final String? sku;
  final String? displayName;
  final String? blockReason;
}
