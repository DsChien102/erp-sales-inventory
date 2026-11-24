import 'package:erp/core/validation/tax_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tax code', () {
    test('normalize trims whitespace and keeps the branch dash', () {
      expect(normalizeTaxCode(' 0101234567-001 '), '0101234567-001');
    });

    test('accepts 10 digits, 12 digits and 10-3 branch format', () {
      expect(isValidTaxCode('0123456789'), isTrue);
      expect(isValidTaxCode('012345678901'), isTrue);
      expect(isValidTaxCode('0123456789-001'), isTrue);
    });

    test('rejects 13 continuous digits and other malformed values', () {
      expect(isValidTaxCode('0123456789012'), isFalse);
      expect(isValidTaxCode('123456789'), isFalse);
      expect(isValidTaxCode('12345678901234'), isFalse);
      expect(isValidTaxCode('012345678A'), isFalse);
      expect(isValidTaxCode('0123456789-01'), isFalse);
      expect(isValidTaxCode('01234567-0001'), isFalse);
      expect(isValidTaxCode('01012345678'), isFalse);
      expect(isValidTaxCode('0101234567 001'), isFalse);
    });

    test('compactTaxCodeInput bỏ khoảng trắng và gắn gạch cho 13 số liền', () {
      expect(compactTaxCodeInput('0101234567 001'), '0101234567-001');
      expect(compactTaxCodeInput(' 0101 2345 67 '), '0101234567');
      expect(compactTaxCodeInput(''), '');
    });

    test('message names the three accepted formats', () {
      expect(
        taxCodeFormatMessage,
        'Mã số thuế phải gồm 10 hoặc 12 chữ số, hoặc dạng chi nhánh 10 số-3 số (VD: 0123456789-001).',
      );
    });
  });
}
