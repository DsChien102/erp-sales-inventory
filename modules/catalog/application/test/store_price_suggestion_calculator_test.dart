import 'package:test/test.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/suggest_product_unit_price/store_price_suggestion_calculator.dart';

void main() {
  group('StorePriceSuggestionCalculator', () {
    test('scaleBasePriceForUnit multiplies by conversion rate', () {
      expect(
        StorePriceSuggestionCalculator.scaleBasePriceForUnit(
          basePricePerBaseUnit: 100000,
          conversionRateToBase: 10,
        ),
        1000000,
      );
      expect(
        StorePriceSuggestionCalculator.scaleBasePriceForUnit(
          basePricePerBaseUnit: 100000,
          conversionRateToBase: 1000,
        ),
        100000000,
      );
    });

    test('scaleBasePriceForUnit keeps base when rate is 1 or invalid', () {
      expect(
        StorePriceSuggestionCalculator.scaleBasePriceForUnit(
          basePricePerBaseUnit: 100000,
          conversionRateToBase: 1,
        ),
        100000,
      );
      expect(
        StorePriceSuggestionCalculator.scaleBasePriceForUnit(
          basePricePerBaseUnit: 100000,
          conversionRateToBase: 0,
        ),
        100000,
      );
    });
  });
}
