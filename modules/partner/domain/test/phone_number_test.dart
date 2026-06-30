import 'package:test/test.dart';
import 'package:vet45_partner_domain/src/value_objects/phone_number.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('PhoneNumber', () {
    test('normalizes separators', () {
      final value = PhoneNumber('0987 654-321');
      expect(value.normalized, '0987654321');
    });

    test('keeps leading plus', () {
      final value = PhoneNumber('+84 987 654 321');
      expect(value.normalized, '+84987654321');
    });

    test('throws when invalid length', () {
      expect(
        () => PhoneNumber('12'),
        throwsA(isA<DomainException>()),
      );
    });
  });
}
