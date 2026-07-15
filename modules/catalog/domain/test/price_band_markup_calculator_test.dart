import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('PriceBandMarkupConfig', () {
    test('rejects a negative list markup ratio', () {
      expect(
        () => PriceBandMarkupConfig(listMarkupRatio: -0.01),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('rejects a floor markup ratio greater than list markup ratio', () {
      expect(
        () => PriceBandMarkupConfig(
          listMarkupRatio: 0.20,
          floorMarkupRatio: 0.30,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('PriceBandMarkupCalculator', () {
    test('calculates and rounds list and floor prices to nearest VND', () {
      final result = PriceBandMarkupCalculator.calculate(
        basePriceForUnit: 50000,
        config: PriceBandMarkupConfig(
          listMarkupRatio: 0.40,
          floorMarkupRatio: 0.20,
        ),
      );

      expect(result.listPrice, 70000);
      expect(result.floorPrice, 60000);
    });

    test('preserves a missing floor price', () {
      final result = PriceBandMarkupCalculator.calculate(
        basePriceForUnit: 50000,
        config: PriceBandMarkupConfig(listMarkupRatio: 0.35),
      );

      expect(result.listPrice, 67500);
      expect(result.floorPrice, isNull);
    });

    test('uses the selling-unit base price after conversion', () {
      final result = PriceBandMarkupCalculator.calculate(
        basePriceForUnit: 500000,
        config: PriceBandMarkupConfig(
          listMarkupRatio: 0.30,
          floorMarkupRatio: 0.10,
        ),
      );

      expect(result.listPrice, 650000);
      expect(result.floorPrice, 550000);
    });

    test('rounds fractional VND instead of truncating', () {
      final result = PriceBandMarkupCalculator.calculate(
        basePriceForUnit: 101,
        config: PriceBandMarkupConfig(listMarkupRatio: 0.005),
      );

      expect(result.listPrice, 102);
    });
  });

  group('ProductUnitPriceBand calculation modes', () {
    test('custom config stores its ratios and materialized prices', () {
      final band = ProductUnitPriceBand.setCustomConfig(
        id: 'band-custom',
        tenantId: const TenantId('tenant-1'),
        productId: const ProductId('product-1'),
        productUnitId: 'unit-bottle',
        basePriceForUnit: 50000,
        markupConfig: PriceBandMarkupConfig(
          listMarkupRatio: 0.35,
          floorMarkupRatio: 0.15,
        ),
      );

      expect(band.calculationMode, PriceBandCalculationMode.customConfig);
      expect(band.storePriceRuleId, isNull);
      expect(band.markupConfig?.listMarkupRatio, 0.35);
      expect(band.markupConfig?.floorMarkupRatio, 0.15);
      expect(band.listBeforeVat?.amount, 67500);
      expect(band.floorBeforeVat?.amount, 57500);
      expect(band.listAfterVat?.amount, 67500);
      expect(band.floorAfterVat?.amount, 57500);
    });

    test('manual stores absolute prices without a formula source', () {
      final band = ProductUnitPriceBand.setManual(
        id: 'band-manual',
        tenantId: const TenantId('tenant-1'),
        productId: const ProductId('product-1'),
        productUnitId: 'unit-bottle',
        listBeforeVat: 70000,
        floorBeforeVat: 60000,
        listAfterVat: 70000,
        floorAfterVat: 60000,
      );

      expect(band.calculationMode, PriceBandCalculationMode.manual);
      expect(band.storePriceRuleId, isNull);
      expect(band.markupConfig, isNull);
    });

    test('store rule keeps the rule reference but not custom ratios', () {
      final band = ProductUnitPriceBand.setRuleBased(
        id: 'band-rule',
        tenantId: const TenantId('tenant-1'),
        productId: const ProductId('product-1'),
        productUnitId: 'unit-bottle',
        storePriceRuleId: 'rule-1',
        basePriceForUnit: 50000,
        ruleConfig: PriceBandMarkupConfig(
          listMarkupRatio: 0.40,
          floorMarkupRatio: 0.20,
        ),
      );

      expect(band.calculationMode, PriceBandCalculationMode.ruleBased);
      expect(band.storePriceRuleId, 'rule-1');
      expect(band.markupConfig, isNull);
      expect(band.listBeforeVat?.amount, 70000);
      expect(band.floorBeforeVat?.amount, 60000);
    });
  });
}
