import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VMoneyValidator', () {
    test('format adds thousand separators with comma', () {
      expect(VMoneyValidator.format(0), '0');
      expect(VMoneyValidator.format(1000), '1,000');
      expect(VMoneyValidator.format(1234567), '1,234,567');
    });

    test('parse strips separators', () {
      expect(VMoneyValidator.parse(''), isNull);
      expect(VMoneyValidator.parse('1,234,567'), 1234567);
      expect(VMoneyValidator.parse('100'), 100);
    });

    test('optional empty value is valid', () {
      expect(VMoneyValidator.isValid(''), isTrue);
      expect(VMoneyValidator.validate('', isRequired: false), isNull);
    });

    test('required empty value returns required message', () {
      expect(
        VMoneyValidator.validate('', isRequired: true),
        VMoneyValidator.defaultRequiredMessage,
      );
    });

    test('rejects value below min', () {
      expect(
        VMoneyValidator.validate('500', isRequired: false, min: 1000),
        VMoneyValidator.defaultMinMessage(1000),
      );
    });

    test('rejects value above max', () {
      expect(
        VMoneyValidator.validate('2,000', isRequired: false, max: 1000),
        VMoneyValidator.defaultMaxMessage(1000),
      );
    });

    test('valid amount passes', () {
      expect(
        VMoneyValidator.validate('1,500', isRequired: true, min: 1000, max: 5000),
        isNull,
      );
    });
  });
}
