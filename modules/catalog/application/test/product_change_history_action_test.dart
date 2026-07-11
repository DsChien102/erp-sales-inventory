import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';

void main() {
  group('ProductChangeHistoryAction', () {
    test('tryParse covers category-mapper aliases', () {
      expect(
        ProductChangeHistoryAction.tryParse('CREATED'),
        ProductChangeHistoryAction.created,
      );
      expect(
        ProductChangeHistoryAction.tryParse('product_created'),
        ProductChangeHistoryAction.created,
      );
      expect(
        ProductChangeHistoryAction.tryParse('add_product_unit')?.category,
        ProductChangeCategory.units,
      );
      expect(
        ProductChangeHistoryAction.tryParse('custom_field_values_updated')
            ?.category,
        ProductChangeCategory.customFields,
      );
      expect(
        ProductChangeHistoryAction.tryParse('deactivate_product')?.category,
        ProductChangeCategory.status,
      );
      expect(ProductChangeHistoryAction.tryParse('unknown'), isNull);
    });

    test('category mapper delegates to action enum', () {
      expect(
        ProductChangeCategoryMapper.fromAction('set_initial_price_band'),
        ProductChangeCategory.pricing,
      );
      expect(
        ProductChangeCategoryMapper.fromAction('not-a-real-action'),
        ProductChangeCategory.other,
      );
    });

    test('every action has a category', () {
      for (final action in ProductChangeHistoryAction.values) {
        expect(action.category, isA<ProductChangeCategory>());
      }
    });
  });
}
