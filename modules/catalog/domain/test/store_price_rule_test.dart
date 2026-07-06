import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';

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
}
