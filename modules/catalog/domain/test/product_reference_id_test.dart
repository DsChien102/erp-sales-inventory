import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('ProductReferenceId', () {
    test('accepts explicit legacy code SP-0001', () {
      final referenceId = ProductReferenceId('SP-0001');

      expect(referenceId.value, 'SP-0001');
    });

    test('rejects invalid patterns', () {
      expect(() => ProductReferenceId(''), throwsA(isA<DomainException>()));
      expect(() => ProductReferenceId('ab'), throwsA(isA<DomainException>()));
      expect(
        () => ProductReferenceId('-bad'),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => ProductReferenceId('bad space'),
        throwsA(isA<DomainException>()),
      );
    });

    test('fromProductId is deterministic for a UUID', () {
      const productId = ProductId('550e8400-e29b-41d4-a716-446655440000');

      final first = ProductReferenceId.fromProductId(productId);
      final second = ProductReferenceId.fromProductId(productId);

      expect(first.value, second.value);
      expect(first.value, startsWith('P'));
      expect(first.value.length, 11);
    });
  });
}
