import 'not_sellable_product_dto.dart';
import 'sellable_product_dto.dart';

/// Authoritative outcome of resolving one requested product id.
enum SellableProductResolution { sellable, notSellable, notFound }

/// Per-id resolution result.
///
/// Callers distinguish infrastructure failure (thrown exception) from business
/// truth (this resolution) instead of collapsing both into a missing product.
final class SellableProductResolutionDto {
  const SellableProductResolutionDto({
    required this.productId,
    required this.resolution,
    this.product,
    this.notSellable,
  });

  final String productId;
  final SellableProductResolution resolution;

  /// Full sellable snapshot; only present when [resolution] is
  /// [SellableProductResolution.sellable].
  final SellableProductDto? product;

  /// Blocked product identity; only present when [resolution] is
  /// [SellableProductResolution.notSellable].
  final NotSellableProductDto? notSellable;
}
