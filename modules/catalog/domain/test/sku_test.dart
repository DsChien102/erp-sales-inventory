import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('Sku', () {
    test('trims and uppercases value', () {
      expect(Sku('  ab-12  ').value, 'AB-12');
    });

    test('throws when blank after normalize', () {
      expect(() => Sku('   '), throwsA(isA<DomainException>()));
    });
  });
}
