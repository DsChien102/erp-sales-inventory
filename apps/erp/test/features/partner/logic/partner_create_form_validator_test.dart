import 'package:erp/features/partner/logic/partner_create_form_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PartnerCreateFormValidator.isValidTaxCode', () {
    test('accepts empty, 10 digits, 12 digits and 10-3 format', () {
      for (final value in [
        '',
        '0101234567',
        '001099012345',
        '0101234567-001',
      ]) {
        expect(PartnerCreateFormValidator.isValidTaxCode(value), isTrue, reason: value);
      }
    });

    test('accepts 13 digits without separator (normalized to 10-3)', () {
      expect(PartnerCreateFormValidator.isValidTaxCode('6868686868773'), isTrue);
    });

    test('rejects malformed values', () {
      for (final value in [
        '123',
        '01012345678',
        '0101234567-01',
        '010123-4567001',
        '0101234567--001',
        '01A0123456',
      ]) {
        expect(PartnerCreateFormValidator.isValidTaxCode(value), isFalse, reason: value);
      }
    });
  });

  group('PartnerCreateFormValidator.normalizeTaxCode', () {
    test('inserts separator for 13 contiguous digits', () {
      expect(
        PartnerCreateFormValidator.normalizeTaxCode('6868686868773'),
        '6868686868-773',
      );
    });

    test('keeps dash and strips whitespace', () {
      expect(
        PartnerCreateFormValidator.normalizeTaxCode(' 0101234567-001 '),
        '0101234567-001',
      );
      expect(
        PartnerCreateFormValidator.normalizeTaxCode('0101 234 567'),
        '0101234567',
      );
    });
  });
}
