import 'package:test/test.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('PartnerTransactionHistoryCriteria', () {
    test('normalizes blank keyword to null', () {
      final criteria = PartnerTransactionHistoryCriteria(keyword: '   ');

      expect(criteria.keyword, isNull);
    });

    test('trims keyword', () {
      final criteria = PartnerTransactionHistoryCriteria(keyword: '  SO-001  ');

      expect(criteria.keyword, 'SO-001');
    });

    test('rejects invalid date range', () {
      expect(
        () => PartnerTransactionHistoryCriteria(
          from: DateTime(2026, 6, 30),
          to: DateTime(2026, 6, 1),
        ),
        throwsA(isA<DomainException>()),
      );
    });
  });
}
