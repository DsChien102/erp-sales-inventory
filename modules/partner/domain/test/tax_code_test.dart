import 'package:test/test.dart';
import 'package:vet45_partner_domain/src/value_objects/tax_code.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('TaxCode', () {
    test('accepts valid alphanumeric tax codes', () {
      final code = TaxCode('0102030405');
      expect(code.value, '0102030405');
      expect(code.normalized, '0102030405');
    });

    test('accepts alphanumeric codes with lowercase letters', () {
      final code = TaxCode('0102abc405');
      expect(code.value, '0102abc405');
      expect(code.normalized, '0102ABC405');
    });

    test('throws when contains special characters', () {
      expect(
        () => TaxCode('0102030405-001'),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => TaxCode('0102030405_abc'),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => TaxCode('0102030405!'),
        throwsA(isA<DomainException>()),
      );
    });

    test('throws when invalid length', () {
      expect(
        () => TaxCode('1234567'),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => TaxCode('12345678901234567'),
        throwsA(isA<DomainException>()),
      );
    });
  });
}
