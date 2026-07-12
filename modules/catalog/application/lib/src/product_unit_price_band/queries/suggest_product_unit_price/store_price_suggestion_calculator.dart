/// Computes suggested list/floor prices from base price and store rule markups.
abstract final class StorePriceSuggestionCalculator {
  static ({double listPrice, double floorPrice}) suggest({
    required double basePrice,
    required double listMarkupRatio,
    required double floorMarkupRatio,
  }) {
    final listPrice = (basePrice * (1 + listMarkupRatio)).roundToDouble();
    final floorPrice = (basePrice * (1 + floorMarkupRatio)).roundToDouble();
    return (listPrice: listPrice, floorPrice: floorPrice);
  }

  static int basePriceVersionFor(double basePrice) => basePrice.hashCode;
}
