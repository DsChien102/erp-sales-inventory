import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VNumberValidator', () {
    test('parse integer mode', () {
      expect(VNumberValidator.parse('', allowDecimal: false), isNull);
      expect(VNumberValidator.parse('42', allowDecimal: false), 42);
      expect(VNumberValidator.parse('1,234', allowDecimal: false), 1234);
      expect(VNumberValidator.parse('3.5', allowDecimal: false), isNull);
    });

    test('parse decimal mode', () {
      expect(VNumberValidator.parse('3.14', allowDecimal: true), 3.14);
      expect(VNumberValidator.parse('1,234.5', allowDecimal: true), 1234.5);
      expect(VNumberValidator.parse('10', allowDecimal: true), 10.0);
    });

    test('format integer with thousand separators', () {
      expect(
        VNumberValidator.format(1234567, allowDecimal: false),
        '1,234,567',
      );
    });

    test('format decimal with thousand separators', () {
      expect(
        VNumberValidator.format(1234.5, allowDecimal: true),
        '1,234.5',
      );
    });

    test('optional empty value is valid', () {
      expect(VNumberValidator.validate('', isRequired: false, allowDecimal: false), isNull);
    });

    test('required empty value returns required message', () {
      expect(
        VNumberValidator.validate('', isRequired: true, allowDecimal: false),
        VNumberValidator.defaultRequiredMessage,
      );
    });

    test('rejects value below min', () {
      expect(
        VNumberValidator.validate('2', isRequired: false, allowDecimal: false, min: 5),
        VNumberValidator.defaultMinMessage(5),
      );
    });

    test('rejects value above max', () {
      expect(
        VNumberValidator.validate('15', isRequired: false, allowDecimal: true, max: 10),
        VNumberValidator.defaultMaxMessage(10),
      );
    });

    test('valid number passes', () {
      expect(
        VNumberValidator.validate('7', isRequired: true, allowDecimal: false, min: 0, max: 10),
        isNull,
      );
    });
  });
}
