/// Computes suggested list/floor prices from base price and store rule markups.
library;

abstract final class StorePriceSuggestionCalculator {
  /// Scales product base price (per base unit) to the target selling unit.
  static double scaleBasePriceForUnit({
    required double basePricePerBaseUnit,
    required double conversionRateToBase,
  }) {
    if (conversionRateToBase <= 0) {
      return basePricePerBaseUnit;
    }
    return basePricePerBaseUnit * conversionRateToBase;
  }

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

