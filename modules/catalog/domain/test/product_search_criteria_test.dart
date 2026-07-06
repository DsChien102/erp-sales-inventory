import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';

void main() {
  group('ProductSearchCriteria', () {
    test('defaults to active business status only', () {
      final criteria = ProductSearchCriteria();
      expect(criteria.businessStatuses, {ProductStatus.active});
      expect(criteria.includeSoftDeleted, isFalse);
      expect(criteria.keyword, isNull);
    });

    test('normalizes blank keyword to null', () {
      final criteria = ProductSearchCriteria(keyword: '   ');
      expect(criteria.keyword, isNull);
    });

    test('preserves trimmed keyword', () {
      final criteria = ProductSearchCriteria(keyword: '  Amoxicillin  ');
      expect(criteria.keyword, 'Amoxicillin');
    });
  });
}
