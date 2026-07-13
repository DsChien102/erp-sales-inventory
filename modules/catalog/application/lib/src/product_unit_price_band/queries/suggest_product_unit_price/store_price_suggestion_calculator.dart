/// Computes suggested list/floor prices from base price and store rule markups.
abstract final class StorePriceSuggestionCalculator {
  static ({int listBeforeVat, int floorBeforeVat}) suggest({
    required double basePrice,
    required double listMarkupRatio,
    required double floorMarkupRatio,
  }) {
    final listBeforeVat = (basePrice * (1 + listMarkupRatio)).round();
    final floorBeforeVat = (basePrice * (1 + floorMarkupRatio)).round();
    return (listBeforeVat: listBeforeVat, floorBeforeVat: floorBeforeVat);
  }

  static int basePriceVersionFor(double basePrice) => basePrice.hashCode;
}
