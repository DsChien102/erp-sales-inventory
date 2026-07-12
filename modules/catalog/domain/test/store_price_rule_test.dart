import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('Store price rule business rules', () {
    test('MarkupRatioMustBeNonNegativeRule rejects negative ratio', () {
      final rule = MarkupRatioMustBeNonNegativeRule(ratio: -0.1);
      expect(rule.isBroken(), isTrue);
    });

    test('SuggestedFloorNotGreaterThanListRule rejects floor > list', () {
      final rule = SuggestedFloorNotGreaterThanListRule(
        basePrice: 100,
        listMarkupRatio: 0.1,
        floorMarkupRatio: 0.5,
      );
      expect(rule.isBroken(), isTrue);
    });

    test('SuggestedFloorNotGreaterThanListRule passes valid markups', () {
      final rule = SuggestedFloorNotGreaterThanListRule(
        basePrice: 80000,
        listMarkupRatio: 0.5,
        floorMarkupRatio: 0.25,
      );
      expect(rule.isBroken(), isFalse);
    });
  });

  group('StorePriceRule aggregate', () {
    test('create rejects negative markup', () {
      expect(
        () => StorePriceRule.create(
          id: 'rule-1',
          tenantId: 'tenant-1',
          name: 'Default',
          listMarkupRatio: -0.1,
          floorMarkupRatio: 0.1,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('replace updates markups', () {
      final rule = StorePriceRule.create(
        id: 'rule-1',
        tenantId: 'tenant-1',
        name: 'Default',
        listMarkupRatio: 0.5,
        floorMarkupRatio: 0.25,
      );

      final updated = rule.replace(
        name: 'Updated',
        listMarkupRatio: 0.4,
        floorMarkupRatio: 0.2,
      );

      expect(updated.name, 'Updated');
      expect(updated.listMarkupRatio, 0.4);
      expect(updated.floorMarkupRatio, 0.2);
    });
  });
}
